variable "aws_region" {
  type        = string
  description = "AWS region used for bootstrap resources."
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming."
  default     = "health-check"
}

variable "github_owner" {
  type        = string
  description = "GitHub organization or user that owns the repository."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name."
}

variable "environments" {
  type        = set(string)
  description = "Environments that receive GitHub OIDC deployment roles."
  default     = ["staging", "prod"]
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for Terraform remote state."
}

variable "state_lock_table_name" {
  type        = string
  description = "DynamoDB table name for Terraform state locking."
}

variable "github_oidc_thumbprints" {
  type        = list(string)
  description = "Thumbprints for GitHub's OIDC provider. If the provider already exists in the account, import it instead of creating another one."
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
