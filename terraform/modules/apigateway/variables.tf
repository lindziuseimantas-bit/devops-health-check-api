variable "env" {
  type        = string
  description = "Environment name."
}

variable "name_prefix" {
  type        = string
  description = "Prefix for named resources."
}

variable "lambda_function_name" {
  type        = string
  description = "Lambda function name."
}

variable "lambda_invoke_arn" {
  type        = string
  description = "Lambda invoke ARN."
}

variable "throttle_rate_limit" {
  type        = number
  description = "Usage plan steady-state requests per second."
}

variable "throttle_burst_limit" {
  type        = number
  description = "Usage plan burst limit."
}

variable "quota_limit" {
  type        = number
  description = "Monthly usage plan quota."
}
