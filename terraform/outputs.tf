output "health_endpoint_url" {
  description = "Health endpoint URL. Send POST / GET requests with x-api-key and JSON body containing payload."
  value       = module.apigateway.health_endpoint_url
}

output "api_key_id" {
  description = "API Gateway API key ID. Retrieve the value with aws apigateway get-api-key --api-key <id> --include-value."
  value       = module.apigateway.api_key_id
}

output "lambda_function_name" {
  value = module.lambda.function_name
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "kms_key_arn" {
  value = module.kms.key_arn
}
