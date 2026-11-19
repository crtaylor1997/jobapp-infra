# Other stacks can read these with terraform_remote_state (key network-<env>.tfstate).

output "vpc_id" {
  value = module.network.vpc_id
}

output "vpc_cidr" {
  value = module.network.vpc_cidr
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "lambda_security_group_id" {
  value = module.network.lambda_security_group_id
}

output "s3_vpc_endpoint_id" {
  value = module.network.s3_vpc_endpoint_id
}

output "dynamodb_vpc_endpoint_id" {
  value = module.network.dynamodb_vpc_endpoint_id
}

output "nat_gateway_ids" {
  value = module.network.nat_gateway_ids
}
