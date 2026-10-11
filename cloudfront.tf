data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

# Origin Access Control signiert die Anfragen von CloudFront an S3.
# Der Bucket bleibt dadurch privat, kein oeffentlicher Endpunkt noetig.
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "website-oac"
  description                       = "Zugriff von CloudFront auf den Website-Bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  comment             = "Unternehmenswebsite"
  default_root_object = "index.html"
  price_class         = "PriceClass_All"
  is_ipv6_enabled     = true # Default ist false, sonst laeuft der AAAA-Record ins Leere

  aliases = [var.domain_name]

  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "s3-website"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-website"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress               = true
  }

  # Die Bucket Policy erlaubt nur GetObject, kein ListBucket. S3 antwortet
  # auf einen unbekannten Pfad deshalb mit 403 statt 404. Beides faengt
  # CloudFront ab und liefert die eigene Fehlerseite aus.
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Mit dem mitgelieferten CloudFront-Zertifikat waere die Security Policy
  # fest auf TLSv1 und minimum_protocol_version wuerde ignoriert. Nur mit
  # eigenem Zertifikat laesst sich TLS 1.2 erzwingen.
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.website.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
