# create_before_destroy, weil die Distribution durchgaengig auf ein gueltiges
# Zertifikat zeigen muss. Sonst wuerde bei einer Erneuerung erst geloescht.
resource "aws_acm_certificate" "website" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Legt nichts an, sondern wartet, bis ACM den DNS-Eintrag gesehen und das
# Zertifikat ausgestellt hat. Laeuft in einen Timeout, solange die Nameserver
# beim Registrar noch nicht auf Route 53 zeigen.
resource "aws_acm_certificate_validation" "website" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.website.arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]
}
