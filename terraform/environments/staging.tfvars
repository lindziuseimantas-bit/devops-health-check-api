aws_region = "eu-central-1"
env        = "staging"

project_name = "health-check"
vpc_cidr     = "10.10.0.0/16"

lambda_memory_size = 128
lambda_timeout     = 10
log_retention_days = 14

api_throttle_rate_limit  = 5
api_throttle_burst_limit = 10
api_quota_limit          = 10000
