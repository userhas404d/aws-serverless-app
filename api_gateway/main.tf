# https://aws.amazon.com/getting-started/projects/build-serverless-web-app-lambda-apigateway-s3-dynamodb-cognito/module-4/

variable "api_gateway_name" {
  default     = "test"
  type        = "string"
  description = "Name of the api gateway"
}

variable "cognito_user_pool" {}

variable "lambda_arn" {}

variable "environment" {}

variable "allowed_headers" {
  description = "Allowed headers"
  type        = "list"

  default = [
    "Content-Type",
    "X-Amz-Date",
    "Authorization",
    "X-Api-Key",
    "X-Amz-Security-Token",
  ]
}

# var.allowed_methods
variable "allowed_methods" {
  description = "Allowed methods"
  type        = "list"

  default = [
    "OPTIONS",
    "HEAD",
    "GET",
    "POST",
    "PUT",
    "PATCH",
    "DELETE",
  ]
}

# var.allowed_origin
variable "allowed_origin" {
  description = "Allowed origin"
  type        = "string"
  default     = "*"
}

variable "allowed_max_age" {
  description = "Allowed response caching time"
  type        = "string"
  default     = "7200"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.api_gateway_name}"
  description = "Terraform Serverless Application"
}

resource "aws_api_gateway_authorizer" "main" {
  name          = "${var.api_gateway_name}-authorizer"
  rest_api_id   = "${aws_api_gateway_rest_api.main.id}"
  type          = "COGNITO_USER_POOLS"
  provider_arns = ["${var.cognito_user_pool}"]
}

resource "aws_api_gateway_resource" "ride_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  parent_id   = "${aws_api_gateway_rest_api.main.root_resource_id}"
  path_part   = "ride"
}

resource "aws_api_gateway_method" "ride_resource_options" {
  rest_api_id   = "${aws_api_gateway_rest_api.main.id}"
  resource_id   = "${aws_api_gateway_resource.ride_resource.id}"
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = "${aws_api_gateway_authorizer.main.id}"
}

resource "aws_api_gateway_method_response" "ride_resource_response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  resource_id = "${aws_api_gateway_resource.ride_resource.id}"
  http_method = "${aws_api_gateway_method.ride_resource_options.http_method}"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [
    "aws_api_gateway_rest_api.main",
    "aws_api_gateway_resource.ride_resource",
    "aws_api_gateway_method.ride_resource_options",
  ]
}

resource "aws_api_gateway_integration" "ride_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.main.id}"
  resource_id             = "${aws_api_gateway_resource.ride_resource.id}"
  http_method             = "${aws_api_gateway_method.ride_resource_options.http_method}"
  integration_http_method = "${aws_api_gateway_method.ride_resource_options.http_method}"
  type                    = "AWS_PROXY"
  timeout_milliseconds    = 29000
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.lambda_arn}/invocations"
}

resource "aws_api_gateway_integration_response" "ride_resource_response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  resource_id = "${aws_api_gateway_resource.ride_resource.id}"
  http_method = "${aws_api_gateway_method.ride_resource_options.http_method}"
  status_code = "${aws_api_gateway_method_response.ride_resource_response_200.status_code}"

  response_templates {
    "application/json" = ""
  }

  depends_on = [
    "aws_api_gateway_integration.ride_integration",
  ]
}

resource "aws_api_gateway_method" "options_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.main.id}"
  resource_id   = "${aws_api_gateway_resource.ride_resource.id}"
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  resource_id = "${aws_api_gateway_resource.ride_resource.id}"
  http_method = "${aws_api_gateway_method.options_method.http_method}"

  # integration_http_method = "${aws_api_gateway_method.options_method.http_method}"
  type                 = "MOCK"
  timeout_milliseconds = 29000

  depends_on = [
    "aws_api_gateway_method.options_method",
  ]
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  depends_on  = ["aws_api_gateway_integration.ride_integration"]
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  resource_id = "${aws_api_gateway_resource.ride_resource.id}"
  http_method = "${aws_api_gateway_method.options_method.http_method}"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'${join(",", var.allowed_headers)}'"
    "method.response.header.Access-Control-Allow-Methods" = "'${join(",", var.allowed_methods)}'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${var.allowed_origin}'"
  }

  response_templates {
    "application/json" = ""
  }

  depends_on = [
    "aws_api_gateway_method.options_method",
    "aws_api_gateway_integration.options_integration",
  ]
}

resource "aws_api_gateway_method_response" "options_method_response" {
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  resource_id = "${aws_api_gateway_resource.ride_resource.id}"
  http_method = "${aws_api_gateway_method.options_method.http_method}"
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [
    "aws_api_gateway_method.ride_resource_options",
  ]
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${var.lambda_arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.main.id}/*/${aws_api_gateway_method.ride_resource_options.http_method}${aws_api_gateway_resource.ride_resource.path}"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = ["aws_api_gateway_integration.ride_integration"]

  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  stage_name  = "${var.environment}"
}

output "invoke_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}"
}
