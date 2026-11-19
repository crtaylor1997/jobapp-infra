output "ecr_repository_url" {
  description = "Push images here: docker push <url>:<tag>"
  value       = aws_ecr_repository.this.repository_url
}

output "role_name" {
  description = "Attach S3/DynamoDB access policies to this role."
  value       = aws_iam_role.this.name
}

output "role_arn" {
  value = aws_iam_role.this.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.this.name
}

output "function_name" {
  description = "Null until image_tag is set."
  value       = one(aws_lambda_function.this[*].function_name)
}

output "function_arn" {
  value = one(aws_lambda_function.this[*].arn)
}
