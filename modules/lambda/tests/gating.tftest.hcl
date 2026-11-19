# Runs without AWS credentials:  cd modules/lambda; terraform init; terraform test
mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

run "no_image_tag_skips_function" {
  command = plan

  variables {
    name = "jobapp-test-worker"
  }

  assert {
    condition     = length(aws_lambda_function.this) == 0
    error_message = "Function must not be created before an image tag is set."
  }

  assert {
    condition     = aws_ecr_repository.this.name == "jobapp-test-worker"
    error_message = "ECR repo should still be created."
  }
}

run "image_tag_creates_function_outside_vpc" {
  command = plan

  variables {
    name      = "jobapp-test-worker"
    image_tag = "abc123"
  }

  assert {
    condition     = length(aws_lambda_function.this) == 1
    error_message = "Function should be created once image_tag is set."
  }

  assert {
    condition     = length(aws_lambda_function.this[0].vpc_config) == 0
    error_message = "Function should run outside the VPC by default."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.vpc_access) == 0
    error_message = "VPC access policy should only attach when in a VPC."
  }
}
