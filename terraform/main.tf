data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "kms" {
  source = "./modules/kms"

  env         = var.env
  name_prefix = local.name_prefix
  account_id  = data.aws_caller_identity.current.account_id
  region      = data.aws_region.current.region
}

module "vpc" {
  source = "./modules/vpc"

  env         = var.env
  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
}

module "dynamodb" {
  source = "./modules/dynamodb"

  env         = var.env
  table_name  = "${var.env}-requests-db"
  kms_key_arn = module.kms.key_arn
}

module "lambda" {
  source = "./modules/lambda"

  env                = var.env
  function_name      = "${var.env}-health-check-function"
  lambda_source_dir  = "${path.root}/../lambda"
  runtime            = var.lambda_runtime
  memory_size        = var.lambda_memory_size
  timeout            = var.lambda_timeout
  table_name         = module.dynamodb.table_name
  table_arn          = module.dynamodb.table_arn
  log_retention_days = var.log_retention_days
  kms_key_arn        = module.kms.key_arn
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.lambda_security_group_id]
}

module "apigateway" {
  source = "./modules/apigateway"

  env                  = var.env
  name_prefix          = local.name_prefix
  lambda_function_name = module.lambda.function_name
  lambda_invoke_arn    = module.lambda.invoke_arn
  throttle_rate_limit  = var.api_throttle_rate_limit
  throttle_burst_limit = var.api_throttle_burst_limit
  quota_limit          = var.api_quota_limit
}
