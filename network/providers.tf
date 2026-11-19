terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Values come from <env>.backend.hcl. Run through the wrapper:
  #   .\scripts\tf.ps1 network dev plan
  backend "s3" {}
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      Stack       = "network"
      ManagedBy   = "terraform"
    }
  }
}
