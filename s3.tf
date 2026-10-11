# Buckets sind global eindeutig, der Name kommt deshalb aus einer Variablen.
# force_destroy, damit terraform destroy nicht an verbliebenen Objekten
# haengenbleibt. Hier unkritisch, im Bucket liegt nur, was aus dem Repo kommt.
resource "aws_s3_bucket" "website" {
  bucket        = var.bucket_name
  force_destroy = true
}

# Riegel auf Bucket-Ebene. Greift auch dann, wenn eine Policy
# versehentlich oeffentlichen Zugriff erlauben wuerde.
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SSE-S3 ist seit 2023 ohnehin Default. Steht hier explizit, damit die
# Verschluesselung im Code nachweisbar ist.
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
        # SourceArn bindet die Freigabe an genau diese Distribution.
        # Ohne die Bedingung koennte eine fremde Distribution den Bucket
        # als Origin eintragen (Confused Deputy).
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      },
      # Greift im Normalbetrieb nie, CloudFront spricht ohnehin HTTPS mit S3.
      # Deckt aber jeden kuenftigen Zugriffsweg mit ab.
      {
        Sid       = "DenyUnencryptedTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# content_type muss gesetzt werden, sonst liefert S3 octet-stream und der
# Browser laedt die Datei herunter statt sie anzuzeigen.
# etag haelt die Pruefsumme im State, erst dadurch bemerkt Terraform
# eine geaenderte Datei.
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "${path.module}/website/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/website/index.html")
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  source       = "${path.module}/website/error.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/website/error.html")
}
