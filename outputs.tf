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
