variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "jobapp"
}

variable "environment" {
  description = "Short environment name: dev or prd."
  type        = string

  validation {
    condition     = contains(["dev", "prd"], var.environment)
    error_message = "The environment value must be dev or prd."
  }
}

variable "image_tag" {
  description = "Image tag in the ECR repo. Null = create the repo/role/logs but not the function yet."
  type        = string
  default     = null
}

variable "memory_mb" {
  type    = number
  default = 512
}

variable "timeout_seconds" {
  type    = number
  default = 60
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "ecr_force_delete" {
  description = "Let terraform destroy remove the ECR repo even if it has images."
  type        = bool
  default     = false
}
