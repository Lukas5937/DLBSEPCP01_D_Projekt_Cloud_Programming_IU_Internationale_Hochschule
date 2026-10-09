resource "aws_route53_zone" "portfolio" {
  name    = var.domain_name
  comment = "Hosted Zone der Unternehmenswebsite"
}
