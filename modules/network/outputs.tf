output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

output "availability_zones" {
  value = local.azs
}

output "private_subnet_ids" {
  description = "Use these for the Lambda vpc_config.subnet_ids."
  value       = aws_subnet.private[*].id
}

output "private_route_table_ids" {
  value = aws_route_table.private[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "lambda_security_group_id" {
  description = "Use this for the Lambda vpc_config.security_group_ids."
  value       = aws_security_group.lambda.id
}

output "s3_vpc_endpoint_id" {
  description = "Reference in S3 bucket policies (aws:SourceVpce) to restrict access to this VPC."
  value       = aws_vpc_endpoint.s3.id
}

output "dynamodb_vpc_endpoint_id" {
  value = aws_vpc_endpoint.dynamodb.id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.this[*].id
}
