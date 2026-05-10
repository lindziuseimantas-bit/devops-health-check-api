aws_region = "eu-central-1"
env        = "prod"

project_name = "health-check"
vpc_cidr     = "10.20.0.0/16"

lambda_memory_size = 256
lambda_timeout     = 10
log_retention_days = 30

api_throttle_rate_limit  = 20
api_throttle_burst_limit = 50
api_quota_limit          = 100000
