variable "name" {
  description = "Name prefix for all network resources (e.g. jobapp-dev)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "The vpc_cidr value must be a valid IPv4 CIDR block."
  }
}

variable "az_count" {
  description = "Number of availability zones for private subnets. Lambda should use at least 2."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "The az_count value must be between 2 and 4."
  }
}

variable "enable_nat_gateway" {
  description = "Create public subnets, an internet gateway and NAT gateway(s) so private workloads can reach the internet. About $32/month per NAT plus data charges. S3 and DynamoDB do not need this; they use the free gateway endpoints."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway instead of one per AZ (cheaper, less resilient)."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs to CloudWatch Logs."
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "Retention in days for the flow log group."
  type        = number
  default     = 14
}

variable "tags" {
  description = "Extra tags applied to every resource in the module."
  type        = map(string)
  default     = {}
}
