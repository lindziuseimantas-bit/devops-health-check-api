output "state_bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "state_lock_table_name" {
  value = aws_dynamodb_table.state_lock.name
}

output "state_kms_key_id" {
  value = aws_kms_key.state.key_id
}

output "deployment_role_arns" {
  value = {
    for env, role in aws_iam_role.deploy : env => role.arn
  }
}
