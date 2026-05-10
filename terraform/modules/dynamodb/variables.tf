variable "env" {
  type        = string
  description = "Environment name."
}

variable "table_name" {
  type        = string
  description = "DynamoDB table name."
}

variable "kms_key_arn" {
  type        = string
  description = "Customer managed KMS key ARN for DynamoDB SSE."
}
