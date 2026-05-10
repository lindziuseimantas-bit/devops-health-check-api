variable "env" {
  type        = string
  description = "Environment name."
}

variable "name_prefix" {
  type        = string
  description = "Prefix for named resources."
}

variable "account_id" {
  type        = string
  description = "AWS account ID."
}

variable "region" {
  type        = string
  description = "AWS region."
}
