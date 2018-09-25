variable "domain_name" {
  default     = "getmyuselesswebsite.com"
  type        = "string"
  description = "name of registered domain"
}

variable "environment" {
  default     = "test"
  type        = "string"
  description = "dev | test | prod"
}

# configures A record for web enabled S3 bucket
module "dns" {
  source                     = "dns"
  domain_name                = "${var.domain_name}"
  main_bucket_website_domain = "${module.s3.main_website_domain}"
  main_bucket_hosted_zone_id = "${module.s3.main_bucket_hosted_zone_id}"
}

# creates:
# - (and configures) s3 buckets
# - cognito user pool 
# - cognito user pool client
# - uploads static_content dir to s3 bucket via aws cli
module "s3" {
  source                        = "s3"
  enable_logging                = false
  domain_name                   = "${var.domain_name}"
  environment                   = "${var.environment}"
  pool_name                     = "test-pool"
  cognito_user_pool_client_name = "test-app"
}

module "dynamodb" {
  source      = "dynamo_db"
  table_name  = "Rides"
  environment = "${var.environment}"
  hash_key    = "RideId"
  attribute   = "RideId"
}

module "lambda" {
  source             = "lambda"
  dyanmodb_table_arn = "${module.dynamodb.table_arn}"
  lambda_role_name   = "${var.domain_name}-LambdaRole"
}
