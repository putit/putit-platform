variable "root_domain" {
  type    = string
  default = "putit.io"
}

variable "tenant" {
  type = string
}

variable "environment" {
  type = string
}

locals {
  wildcard_domain = "*.${var.environment}.${var.tenant}.${var.root_domain}"
}

data "aws_route53_zone" "public_hosted_zone" {
  name         = var.root_domain
  private_zone = false
}

resource "aws_acm_certificate" "wildcard" {
  domain_name       = local.wildcard_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "wildcard_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.public_hosted_zone.zone_id
}

resource "aws_acm_certificate_validation" "wildcard" {
  certificate_arn         = aws_acm_certificate.wildcard.arn
  validation_record_fqdns = [for record in aws_route53_record.wildcard_validation : record.fqdn]
}

output "public_route53_hosted_zone_id" {
  value = data.aws_route53_zone.public_hosted_zone.zone_id
}

output "acm_wildcard_cert_arn" {
  value = aws_acm_certificate_validation.wildcard.certificate_arn
}
