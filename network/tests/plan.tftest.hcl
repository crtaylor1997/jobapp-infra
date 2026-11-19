# Plans the stack with a mocked AWS provider (no credentials):
#   terraform init -backend=false
#   terraform test -var-file=dev.tfvars
#   terraform test -var-file=prd.tfvars
mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

run "plan_env" {
  command = plan

  assert {
    condition     = module.network.vpc_cidr == var.vpc_cidr
    error_message = "VPC CIDR should come from the env's tfvars."
  }

  assert {
    condition     = length(module.network.private_subnet_ids) == var.az_count
    error_message = "Expected one private subnet per AZ."
  }

  assert {
    condition     = local.name == "jobapp-${var.environment}"
    error_message = "Resource names should include the environment."
  }
}
