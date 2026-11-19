locals {
  name = "${var.project}-${var.environment}"
}

module "network" {
  source = "../modules/network"

  name               = local.name
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = true
  enable_flow_logs   = var.enable_flow_logs
}
