variable "env" {
  type        = string
  description = "Environment name."
}

variable "name_prefix" {
  type        = string
  description = "Prefix for named resources."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}
