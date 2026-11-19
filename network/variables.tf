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

variable "vpc_cidr" {
  description = "Must not overlap between environments (for future peering/VPN)."
  type        = string
}

variable "az_count" {
  type    = number
  default = 2
}

variable "enable_nat_gateway" {
  description = "Only needed if the Lambda moves into the VPC. About $32/month."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  type    = bool
  default = false
}
