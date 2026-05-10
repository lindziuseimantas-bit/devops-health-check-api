resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.env}-health-check-api"
  description = "Serverless health check API for ${var.env}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "${var.env}-health-check-api"
  }
}

resource "aws_api_gateway_resource" "health" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "health"
}

resource "aws_api_gateway_model" "health_request" {
  rest_api_id  = aws_api_gateway_rest_api.this.id
  name         = "${var.env}HealthCheckRequest"
  content_type = "application/json"

  schema = jsonencode({
    "$schema"             = "http://json-schema.org/draft-04/schema#"
    title                 = "HealthCheckRequest"
    type                  = "object"
    required              = ["payload"]
    additionalProperties  = true
    properties = {
      payload = {}
    }
  })
}

resource "aws_api_gateway_request_validator" "body" {
  name                  = "${var.env}-health-check-body-validator"
  rest_api_id           = aws_api_gateway_rest_api.this.id
  validate_request_body = true
}

resource "aws_api_gateway_method" "health" {
  for_each = toset(["GET", "POST"])

  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.health.id
  http_method          = each.key
  authorization        = "NONE"
  api_key_required     = true
  request_validator_id = aws_api_gateway_request_validator.body.id

  request_models = {
    "application/json" = aws_api_gateway_model.health_request.name
  }
}

resource "aws_api_gateway_integration" "health" {
  for_each = aws_api_gateway_method.health

  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.health.id
  http_method             = each.value.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowExecutionFrom${var.env}ApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode({
      resource_id      = aws_api_gateway_resource.health.id
      method_ids       = [for method in aws_api_gateway_method.health : method.id]
      integration_ids  = [for integration in aws_api_gateway_integration.health : integration.id]
      validator_id     = aws_api_gateway_request_validator.body.id
      model_schema     = aws_api_gateway_model.health_request.schema
      lambda_invoke_id = var.lambda_invoke_arn
    }))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.health
  ]
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.env

  tags = {
    Name = "${var.env}-health-check-stage"
  }
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = var.throttle_burst_limit
    throttling_rate_limit  = var.throttle_rate_limit
    metrics_enabled        = true
  }
}

resource "aws_api_gateway_usage_plan" "this" {
  name        = "${var.env}-health-check-usage-plan"
  description = "Usage plan with throttling and quota for ${var.env} health check API"

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.this.stage_name
  }

  quota_settings {
    limit  = var.quota_limit
    period = "MONTH"
  }

  throttle_settings {
    burst_limit = var.throttle_burst_limit
    rate_limit  = var.throttle_rate_limit
  }

  tags = {
    Name = "${var.env}-health-check-usage-plan"
  }
}

resource "aws_api_gateway_api_key" "this" {
  name        = "${var.env}-health-check-api-key"
  description = "API key for ${var.env} health check API"
  enabled     = true

  tags = {
    Name = "${var.env}-health-check-api-key"
  }
}

resource "aws_api_gateway_usage_plan_key" "this" {
  key_id        = aws_api_gateway_api_key.this.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this.id
}
