terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "Cloud-Programming-Portfolio"
      ManagedBy = "Terraform"
    }
  }
}

# Zweiter Provider nur fuer ACM. CloudFront akzeptiert Zertifikate
# ausschliesslich aus us-east-1, alles andere liegt in eu-central-1.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "Cloud-Programming-Portfolio"
      ManagedBy = "Terraform"
    }
  }
}
