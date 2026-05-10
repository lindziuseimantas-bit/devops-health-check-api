output "function_name" {
  value = aws_lambda_function.health_check.function_name
}

output "function_arn" {
  value = aws_lambda_function.health_check.arn
}

output "invoke_arn" {
  value = aws_lambda_function.health_check.invoke_arn
}

output "role_arn" {
  value = aws_iam_role.lambda.arn
}
