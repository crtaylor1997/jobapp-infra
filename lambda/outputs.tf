output "ecr_repository_url" {
  description = "Push the worker image here."
  value       = module.worker.ecr_repository_url
}

output "role_name" {
  description = "S3/DynamoDB stacks attach their access policies to this role."
  value       = module.worker.role_name
}

output "role_arn" {
  value = module.worker.role_arn
}

output "function_name" {
  description = "Null until image_tag is set."
  value       = module.worker.function_name
}
