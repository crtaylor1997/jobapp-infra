locals {
  name = "${var.project}-${var.environment}"
}

# Runs outside the VPC to keep costs near $0 (see README "Cost decision").
# To move it in, read the network stack's outputs, e.g.:
#
#   data "terraform_remote_state" "network" {
#     backend = "s3"
#     config = {
#       bucket = "<state bucket>"
#       key    = "network-${var.environment}.tfstate"
#       region = var.region
#     }
#   }
#
# then pass vpc_subnet_ids / vpc_security_group_ids below and set
# enable_nat_gateway = true in the network stack.
module "worker" {
  source = "../modules/lambda"

  name               = "${local.name}-worker"
  image_tag          = var.image_tag
  memory_mb          = var.memory_mb
  timeout_seconds    = var.timeout_seconds
  log_retention_days = var.log_retention_days
  ecr_force_delete   = var.ecr_force_delete

  environment_variables = {
    ENVIRONMENT = var.environment
  }
}
