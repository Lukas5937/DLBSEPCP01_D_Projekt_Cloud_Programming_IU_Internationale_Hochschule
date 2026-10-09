output "website_url" {
  description = "Adresse der fertigen Website"
  value       = "https://${var.domain_name}"
}

output "route53_name_servers" {
  description = "Diese vier Nameserver beim Domain-Anbieter eintragen"
  value       = aws_route53_zone.portfolio.name_servers
}

output "cloudfront_domain_name" {
  description = "Domain der CloudFront-Distribution"
  value       = aws_cloudfront_distribution.portfolio.domain_name
}

output "cloudfront_distribution_id" {
  description = "ID der Distribution, wird fuer Invalidierungen gebraucht"
  value       = aws_cloudfront_distribution.portfolio.id
}

output "bucket_arn" {
  description = "ARN des Buckets"
  value       = aws_s3_bucket.portfolio.arn
}

output "bucket_regional_domain_name" {
  description = "Regionaler Domainname des Buckets, der Ursprung fuer CloudFront"
  value       = aws_s3_bucket.portfolio.bucket_regional_domain_name
}
