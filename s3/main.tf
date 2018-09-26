# getmyuselesswebsite.com

variable "domain_name" {
  type        = "string"
  description = "name of registered domain"
}

variable "environment" {
  default     = "test"
  type        = "string"
  description = "dev | test | prod"
}

variable "enable_logging" {
  default     = false
  description = "boolean to enable or disable s3 logging"
}

variable "pool_name" {
  type        = "string"
  description = "name of the cognito pool"
  default     = "test-pool"
}

variable "cognito_user_pool_client_name" {
  type        = "string"
  description = "Name of the client application"
  default     = "testapp"
}

variable "invoke_url" {}

locals {
  logging_bucket_id             = "${join(",", aws_s3_bucket.main_logging.*.id)}"
  logging_bucket_hosted_zone_id = "${join(",", aws_s3_bucket.main_logging.*.hosted_zone_id)}"
  logging_bucket_website_domain = "${join(",", aws_s3_bucket.main_logging.*.website_domain)}"

  main_bucket_id             = "${join(",", aws_s3_bucket.main.*.id)}"
  main_bucket_hosted_zone_id = "${join(",", aws_s3_bucket.main.*.hosted_zone_id)}"
  main_bucket_website_domain = "${join(",", aws_s3_bucket.main.*.website_domain)}"

  bucket_id             = "${var.enable_logging ? local.logging_bucket_id : local.main_bucket_id}"
  bucket_hosted_zone_id = "${var.enable_logging ? local.logging_bucket_hosted_zone_id : local.main_bucket_hosted_zone_id}"
  bucket_website_domain = "${var.enable_logging ? local.logging_bucket_website_domain : local.main_bucket_website_domain}"
}

# s3 logging target - created conditionally
resource "aws_s3_bucket" "logging_target" {
  count = "${var.enable_logging ? 1 : 0}"

  bucket = "${var.domain_name}-logs"
  acl    = "log-delivery-write"
}

# "main" bucket policy

data "aws_iam_policy_document" "main_bucket_read" {
  statement = {
    sid       = "PublicReadGetObject"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.domain_name}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

# main bucket - without logging
resource "aws_s3_bucket" "main" {
  count         = "${!var.enable_logging ? 1 : 0}"
  bucket        = "${var.domain_name}"
  acl           = "public-read"
  policy        = "${data.aws_iam_policy_document.main_bucket_read.json}"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags {
    Name        = "${var.domain_name}"
    Environment = "${var.environment}"
  }
}

# main bucket - with logging
resource "aws_s3_bucket" "main_logging" {
  count         = "${var.enable_logging ? 1 : 0}"
  bucket        = "${var.domain_name}"
  acl           = "public-read"
  policy        = "${data.aws_iam_policy_document.main_bucket_read.json}"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags {
    Name        = "${var.domain_name}"
    Environment = "${var.environment}"
  }

  logging {
    target_bucket = "${aws_s3_bucket.logging_target.id}"
    target_prefix = "log/"
  }
}

# www bucket

data "aws_iam_policy_document" "www_bucket_read" {
  statement = {
    sid       = "PublicReadGetObject"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::www.${var.domain_name}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket" "www" {
  bucket        = "www.${var.domain_name}"
  acl           = "public-read"
  policy        = "${data.aws_iam_policy_document.www_bucket_read.json}"
  force_destroy = true

  website {
    redirect_all_requests_to = "${var.domain_name}"
  }

  tags {
    Name        = "www.${var.domain_name}"
    Environment = "${var.environment}"
  }
}

# bucket objects

# resource "aws_s3_bucket_object" "index" {
#   bucket       = "${local.bucket_id}"
#   key          = "index.html"
#   source       = "${path.module}/../static_content/index.html"
#   etag         = "${md5(file("${path.module}/../static_content/index.html"))}"
#   content_type = "text/html"
# }

# resource "aws_s3_bucket_object" "errror" {
#   bucket       = "${local.bucket_id}"
#   key          = "error.html"
#   source       = "${path.module}/../static_content/error.html"
#   etag         = "${md5(file("${path.module}/../static_content/error.html"))}"
#   content_type = "text/html"
# }

resource "null_resource" "s3_sync" {
  depends_on = ["local_file.config"]

  provisioner "local-exec" {
    working_dir = "${path.module}/../static_content"
    command     = "aws s3 sync . s3://${local.bucket_id}"
  }
}

output "main_bucket_hosted_zone_id" {
  description = "hosted zone id of the main bucket"
  value       = "${local.bucket_hosted_zone_id}"
}

output "main_website_domain" {
  description = "name of the main bucket"
  value       = "${local.bucket_website_domain}"
}

# configure cognito
resource "aws_cognito_user_pool" "pool" {
  name = "${var.pool_name}"
}

resource "aws_cognito_user_pool_client" "client" {
  name = "${var.cognito_user_pool_client_name}"

  user_pool_id = "${aws_cognito_user_pool.pool.id}"

  generate_secret     = false
  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH"]
}

output "cognito_user_pool_arn" {
  value = "${aws_cognito_user_pool.pool.arn}"
}

# modify config.js

data "aws_region" "current" {}

data "template_file" "config" {
  template = "${file("${path.module}/../static_content/config_templates/config.js")}"

  vars {
    user_pool_id        = "${aws_cognito_user_pool.pool.id}"
    user_pool_client_id = "${aws_cognito_user_pool_client.client.id}"
    region              = "${data.aws_region.current.name}"
    invoke_url          = "${var.invoke_url}"
  }
}

resource "local_file" "config" {
  content  = "${data.template_file.config.rendered}"
  filename = "${path.module}/../static_content/js/config.js"
}
