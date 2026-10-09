variable "aws_region" {
  description = "AWS-Region, in der die Ressourcen angelegt werden"
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "Weltweit eindeutiger Name des S3-Buckets"
  type        = string
}
