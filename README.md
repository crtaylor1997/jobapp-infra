# jobapp-infra

Terraform for the job application pipeline on AWS.

```
scripts/           bootstrap-state.ps1: creates the S3 state bucket + backend.hcl
modules/network/   Reusable VPC module
envs/dev/          Dev environment (uses the S3 backend)
```

## Network foundation (`modules/network`)

| Piece | Details | Cost |
|---|---|---|
| VPC | `10.0.0.0/16`, DNS hostnames on | free |
| Private subnets | 2 x `/20` across 2 AZs, no public IPs. Lambda goes here | free |
| Gateway endpoints | S3 + DynamoDB routed privately from the private route tables | free |
| Lambda security group | No inbound, HTTPS (443) outbound only | free |
| Default SG | All rules stripped | free |
| NAT (optional) | `enable_nat_gateway = true` adds public subnets, IGW and one NAT | about $32/mo + data |
| Flow logs (optional) | `enable_flow_logs = true`, CloudWatch, 14-day retention | usage-based |

With the defaults, the VPC has **no internet path at all**. Lambda can reach S3
and DynamoDB through the gateway endpoints. Turn on NAT once Lambda needs to call
outside APIs (job boards, an LLM API, and so on).

## Deploy

Prereqs: Terraform >= 1.10, AWS CLI v2 with credentials (`aws configure` or `AWS_PROFILE`).

```powershell
# 1. State bucket + envs\dev\backend.hcl (idempotent, safe to re-run)
.\scripts\bootstrap-state.ps1                      # options: -Region, -Profile, -Environments dev,prod, -Force

# 2. Dev network
cd envs\dev
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

## Cost decision: Lambda runs outside the VPC

To keep costs close to $0, the Lambda is **not** attached to the VPC. It runs in
AWS's managed network with direct internet access (job boards, LLM APIs) and
reaches S3 and DynamoDB over their public endpoints, secured by IAM and TLS.

Putting a Lambda in a public subnet would not work: a VPC-attached Lambda never
gets a public IP, so its only route to the internet is through a NAT gateway.

The VPC above is still deployed (it's free) so we can move in later by adding a
`vpc_config` block and setting `enable_nat_gateway = true` (about $32/mo), or
by adding a cheap NAT instance.

## Moving Lambda into the VPC later

```hcl
vpc_config {
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.network.lambda_security_group_id]
}
```

Lock the S3 bucket to this VPC with a bucket policy condition on
`aws:SourceVpce = module.network.s3_vpc_endpoint_id`.
