variable "domain_name" {
  type        = "string"
  description = "name of registered domain"
}

variable "main_bucket_hosted_zone_id" {
  type = "string"
}

variable "main_bucket_website_domain" {
  type = "string"
}

data "aws_route53_zone" "main" {
  name = "${var.domain_name}"
}

resource "aws_route53_record" "main" {
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name    = "${var.domain_name}"
  type    = "A"

  alias {
    name                   = "${var.main_bucket_website_domain}"
    evaluate_target_health = false
    zone_id                = "${var.main_bucket_hosted_zone_id}"
  }
}

resource "aws_route53_record" "www" {
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = "${var.main_bucket_website_domain}"
    evaluate_target_health = false
    zone_id                = "${var.main_bucket_hosted_zone_id}"
  }
}
