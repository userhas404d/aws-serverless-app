# https://aws.amazon.com/getting-started/projects/build-serverless-web-app-lambda-apigateway-s3-dynamodb-cognito/module-3/

variable "dyanmodb_table_arn" {
  type = "string"
}

variable "lambda_role_name" {
  default     = "test-deleteme"
  type        = "string"
  description = "name of the role to assign to the lambda function"
}

# create the Lambda role
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    sid = "AWSLambdaAssumeRole"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid = "AWSLambdaBasicExecutionRole"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    sid = "DynamoDBWriteAccess"

    actions = [
      "dynamodb:PutItem",
    ]

    resources = ["${var.dyanmodb_table_arn}"]
  }
}

resource "aws_iam_policy" "lambda_role" {
  name        = "${var.lambda_role_name}-Policy"
  description = "Policy for aws-serverless-app. Managed by terraform."
  policy      = "${data.aws_iam_policy_document.lambda_policy.json}"
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.lambda_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_trust.json}"
}

resource "aws_iam_role_policy_attachment" "lambda_role" {
  role       = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.lambda_role.arn}"
}

# create the lambda function

resource "aws_lambda_function" "lambda_function" {
  filename         = "${path.module}/../lambda/lambda_package.zip"
  function_name    = "requestUnicorn"
  role             = "${aws_iam_role.lambda_role.arn}"
  handler          = "requestUnicorn.handler"
  source_code_hash = "${base64sha256(file("${path.module}/../lambda/lambda_package.zip"))}"
  runtime          = "nodejs6.10"
}

output "invoke_arn" {
  value = "${aws_lambda_function.lambda_function.invoke_arn}"
}

output "arn" {
  value = "${aws_lambda_function.lambda_function.arn}"
}
