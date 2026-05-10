output "health_endpoint_url" {
  value = "${aws_api_gateway_stage.this.invoke_url}${aws_api_gateway_resource.health.path}"
}

output "rest_api_id" {
  value = aws_api_gateway_rest_api.this.id
}

output "api_key_id" {
  value = aws_api_gateway_api_key.this.id
}
