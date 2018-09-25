# https://aws.amazon.com/getting-started/projects/build-serverless-web-app-lambda-apigateway-s3-dynamodb-cognito/module-3/

variable "table_name" {
  default     = "testtable"
  type        = "string"
  description = "Name of DyanmoDB table"
}

variable "environment" {
  default     = "test"
  type        = "string"
  description = "dev | test | prod"
}

variable "hash_key" {
  type        = "string"
  description = "db hash key"
}

variable "attribute" {
  type = "string"
}

resource "aws_dynamodb_table" "serverless_dynamodb_table" {
  name           = "${var.table_name}"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "${var.hash_key}"

  attribute {
    name = "${var.attribute}"
    type = "S"
  }

  tags {
    Name        = "${var.table_name}"
    Environment = "${var.environment}"
  }
}

output "table_arn" {
  value = "${aws_dynamodb_table.serverless_dynamodb_table.arn}"
}
