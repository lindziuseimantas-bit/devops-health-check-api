variable "env" {
  type        = string
  description = "Environment name."
}

variable "function_name" {
  type        = string
  description = "Lambda function name."
}

variable "lambda_source_dir" {
  type        = string
  description = "Local directory containing Lambda source files."
}

variable "runtime" {
  type        = string
  description = "Lambda runtime."
}

variable "memory_size" {
  type        = number
  description = "Lambda memory in MB."
}

variable "timeout" {
  type        = number
  description = "Lambda timeout in seconds."
}

variable "table_name" {
  type        = string
  description = "DynamoDB table name."
}

variable "table_arn" {
  type        = string
  description = "DynamoDB table ARN."
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days."
}

variable "kms_key_arn" {
  type        = string
  description = "Customer managed KMS key ARN."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for Lambda VPC config."
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs for Lambda VPC config."
}
