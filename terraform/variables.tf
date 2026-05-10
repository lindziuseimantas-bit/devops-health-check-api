variable "aws_region" {
  description = "AWS region where resources are deployed."
  type        = string
}

variable "env" {
  description = "Deployment environment. Must be staging or prod."
  type        = string

  validation {
    condition     = contains(["staging", "prod"], var.env)
    error_message = "env must be either staging or prod."
  }
}

variable "project_name" {
  description = "Project name used for tagging."
  type        = string
  default     = "health-check"
}

variable "lambda_runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB."
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "CloudWatch log retention for the Lambda log group."
  type        = number
  default     = 14
}

variable "api_throttle_rate_limit" {
  description = "API Gateway steady-state requests per second."
  type        = number
}

variable "api_throttle_burst_limit" {
  description = "API Gateway burst requests."
  type        = number
}

variable "api_quota_limit" {
  description = "API Gateway usage plan monthly request quota."
  type        = number
}

variable "vpc_cidr" {
  description = "CIDR block for the Lambda VPC."
  type        = string
}
