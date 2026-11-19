variable "name" {
  description = "Function name. Also used for the ECR repo, IAM role and log group (e.g. jobapp-dev-worker)."
  type        = string
}

variable "image_tag" {
  description = "Tag of the image in this function's ECR repo. Leave null until an image has been pushed; the function is only created once this is set."
  type        = string
  default     = null
}

variable "architecture" {
  description = "CPU architecture of the image. arm64 is ~20% cheaper per GB-second."
  type        = string
  default     = "arm64"

  validation {
    condition     = contains(["arm64", "x86_64"], var.architecture)
    error_message = "The architecture value must be arm64 or x86_64."
  }
}

variable "memory_mb" {
  type    = number
  default = 512
}

variable "timeout_seconds" {
  type    = number
  default = 60
}

variable "environment_variables" {
  description = "Environment variables for the function. Do not put secrets here."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "ecr_keep_images" {
  description = "Number of tagged images to keep in ECR (older ones are expired to save storage)."
  type        = number
  default     = 10
}

variable "ecr_force_delete" {
  description = "Allow terraform destroy to delete the ECR repo even if it still has images."
  type        = bool
  default     = false
}

variable "vpc_subnet_ids" {
  description = "Optional. Subnets to attach the function to. Empty = run outside the VPC (default, free internet egress)."
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "Security groups for the function when vpc_subnet_ids is set."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
