# Die Zone legt Terraform an, die Nameserver muessen danach von Hand beim
# Domain-Anbieter eingetragen werden. Der Anbieter ist kein AWS-Dienst,
# an dieser Stelle endet Infrastructure as Code.
resource "aws_route53_zone" "website" {
  name    = var.domain_name
  comment = "Hosted Zone der Unternehmenswebsite"
}

# ACM gibt pro Domain einen CNAME vor, ueber den der Besitz nachgewiesen wird.
resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for option in aws_acm_certificate.website.domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      type   = option.resource_record_type
      record = option.resource_record_value
    }
  }

  zone_id         = aws_route53_zone.website.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Alias statt CNAME, weil ein CNAME auf der Apex-Domain nicht zulaessig ist.
# Alias-Abfragen sind bei Route 53 ausserdem kostenfrei.
resource "aws_route53_record" "website_ipv4" {
  zone_id = aws_route53_zone.website.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "website_ipv6" {
  zone_id = aws_route53_zone.website.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}
