<#
.SYNOPSIS
  Creates (or re-hardens) the S3 bucket that stores Terraform remote state,
  and writes envs/<env>/backend.hcl for each environment.

.DESCRIPTION
  Idempotent: safe to re-run. If the bucket already exists in your account,
  the script just re-applies the security settings.

  Bucket: <project>-tfstate-<account-id>-<region>
    - Versioning on (recover from bad state writes)
    - SSE-S3 encryption by default
    - All public access blocked, ACLs disabled (BucketOwnerEnforced)
    - Bucket policy denies non-TLS requests
    - Old state versions expire after 90 days

  State locking uses S3 native lockfiles (use_lockfile = true), so no
  DynamoDB lock table is needed.

.EXAMPLE
  .\scripts\bootstrap-state.ps1
  .\scripts\bootstrap-state.ps1 -Region us-west-2 -Profile jobapp
  .\scripts\bootstrap-state.ps1 -Environments dev,prod -Force
#>
[CmdletBinding()]
param(
    [string]   $Region       = "us-east-1",
    [string]   $Project      = "jobapp",
    [string]   $Profile,
    [string[]] $Environments = @("dev"),
    # Overwrite existing envs/<env>/backend.hcl files.
    [switch]   $Force
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSScriptRoot
$TmpDir   = Join-Path ([System.IO.Path]::GetTempPath()) ("tfstate-bootstrap-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $TmpDir | Out-Null

if ($Profile) { $env:AWS_PROFILE = $Profile }
$env:AWS_DEFAULT_REGION = $Region
$env:AWS_PAGER = ""

function Invoke-Aws {
    # Runs the AWS CLI and throws on a non-zero exit code.
    param([Parameter(ValueFromRemainingArguments = $true)] [string[]] $AwsArgs)
    $out = & aws @AwsArgs
    if ($LASTEXITCODE -ne 0) { throw "aws $($AwsArgs -join ' ') failed (exit $LASTEXITCODE)" }
    return $out
}

function Write-JsonFile {
    # Writes UTF-8 without BOM (the AWS CLI rejects a BOM in file:// JSON).
    param([string] $Name, [string] $Json)
    $path = Join-Path $TmpDir $Name
    [System.IO.File]::WriteAllText($path, $Json)
    return "file://$path"
}

try {
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        throw "AWS CLI not found. Install it from https://aws.amazon.com/cli/ and run 'aws configure'."
    }

    $AccountId = Invoke-Aws sts get-caller-identity --query Account --output text
    $AccountId = "$AccountId".Trim()
    $Bucket    = "$Project-tfstate-$AccountId-$Region"
    $BucketArn = "arn:aws:s3:::$Bucket"

    Write-Host "Account : $AccountId"
    Write-Host "Region  : $Region"
    Write-Host "Bucket  : $Bucket"
    Write-Host ""

    # --- Create bucket if needed ------------------------------------------------
    & aws s3api head-bucket --bucket $Bucket 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[skip] Bucket already exists in this account"
    } else {
        Write-Host "[create] Bucket"
        if ($Region -eq "us-east-1") {
            # us-east-1 rejects an explicit LocationConstraint.
            Invoke-Aws s3api create-bucket --bucket $Bucket --region $Region | Out-Null
        } else {
            Invoke-Aws s3api create-bucket --bucket $Bucket --region $Region `
                --create-bucket-configuration "LocationConstraint=$Region" | Out-Null
        }
        Invoke-Aws s3api wait bucket-exists --bucket $Bucket | Out-Null
    }

    # --- Harden -------------------------------------------------------------------
    Write-Host "[apply] Block all public access"
    Invoke-Aws s3api put-public-access-block --bucket $Bucket `
        --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" | Out-Null

    Write-Host "[apply] Disable ACLs (BucketOwnerEnforced)"
    Invoke-Aws s3api put-bucket-ownership-controls --bucket $Bucket `
        --ownership-controls "Rules=[{ObjectOwnership=BucketOwnerEnforced}]" | Out-Null

    Write-Host "[apply] Versioning"
    Invoke-Aws s3api put-bucket-versioning --bucket $Bucket `
        --versioning-configuration "Status=Enabled" | Out-Null

    Write-Host "[apply] Default encryption (SSE-S3)"
    $enc = Write-JsonFile "encryption.json" @'
{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" },
      "BucketKeyEnabled": true
    }
  ]
}
'@
    Invoke-Aws s3api put-bucket-encryption --bucket $Bucket `
        --server-side-encryption-configuration $enc | Out-Null

    Write-Host "[apply] Bucket policy (deny non-TLS)"
    $policy = Write-JsonFile "policy.json" @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": ["$BucketArn", "$BucketArn/*"],
      "Condition": { "Bool": { "aws:SecureTransport": "false" } }
    }
  ]
}
"@
    Invoke-Aws s3api put-bucket-policy --bucket $Bucket --policy $policy | Out-Null

    Write-Host "[apply] Lifecycle (expire old state versions after 90 days)"
    $lifecycle = Write-JsonFile "lifecycle.json" @'
{
  "Rules": [
    {
      "ID": "expire-noncurrent-state",
      "Status": "Enabled",
      "Filter": {},
      "NoncurrentVersionExpiration": { "NoncurrentDays": 90 },
      "AbortIncompleteMultipartUpload": { "DaysAfterInitiation": 7 }
    }
  ]
}
'@
    Invoke-Aws s3api put-bucket-lifecycle-configuration --bucket $Bucket `
        --lifecycle-configuration $lifecycle | Out-Null

    Invoke-Aws s3api put-bucket-tagging --bucket $Bucket `
        --tagging "TagSet=[{Key=Project,Value=$Project},{Key=ManagedBy,Value=bootstrap-script}]" | Out-Null

    # --- backend.hcl per environment ----------------------------------------------
    Write-Host ""
    foreach ($envName in $Environments) {
        $envDir = Join-Path $RepoRoot "envs\$envName"
        if (-not (Test-Path $envDir)) {
            Write-Warning "envs\$envName does not exist; skipping backend.hcl"
            continue
        }
        $hclPath = Join-Path $envDir "backend.hcl"
        if ((Test-Path $hclPath) -and -not $Force) {
            Write-Host "[skip] envs\$envName\backend.hcl exists (use -Force to overwrite)"
            continue
        }
        $hcl = @"
bucket       = "$Bucket"
key          = "$envName/terraform.tfstate"
region       = "$Region"
encrypt      = true
use_lockfile = true
"@
        [System.IO.File]::WriteAllText($hclPath, $hcl + "`n")
        Write-Host "[write] envs\$envName\backend.hcl"
    }

    Write-Host ""
    Write-Host "Done. Next:"
    Write-Host "  cd envs\$($Environments[0])"
    Write-Host "  terraform init -backend-config=backend.hcl"
}
finally {
    Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
}
