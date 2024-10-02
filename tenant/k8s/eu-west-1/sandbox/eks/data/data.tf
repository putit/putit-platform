variable "root_domain" {
  type        = string
  default     = "putit.io"
}

data "aws_route53_zone" "public_hosted_zone" {
  name         = var.root_domain
  private_zone = false
}

output "public_route53_hosted_zone_id" {
  value = data.aws_route53_zone.public_hosted_zone.zone_id
}
