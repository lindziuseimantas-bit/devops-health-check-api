locals {
  name_prefix = "${var.env}-${var.project_name}"

  common_tags = {
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "terraform"
  }
}
