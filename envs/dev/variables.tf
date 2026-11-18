variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "jobapp"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
}

variable "enable_nat_gateway" {
  description = "Turn on once Lambda needs to call the public internet (job boards, LLM APIs)."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  type    = bool
  default = false
}
