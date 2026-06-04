###############################################################################
# AWS UG Mixtli — Root Terraform configuration
#
# Resources provisioned:
#   • S3 bucket (private) for the static site content
#   • CloudFront distribution (HTTPS, custom domain, OAC)
#   • ACM certificate in us-east-1 (required for CloudFront)
#   • Route 53 records (A + AAAA alias to CloudFront, CNAME for ACM validation)
#   • SES email identity & DKIM (sender domain verification)
#   • Lambda + Function URL (sponsor contact form, SES)
#   • Lambda + EventBridge weekly rule (ICS sync → S3 JSON)
#   • IAM roles & policies for both Lambdas (least privilege)
#   • CloudWatch Log Groups for both Lambdas
###############################################################################

terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Recommended: enable remote state once you have an S3 backend bucket.
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "mixtli-web/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# ── Primary region (Lambda + SES + S3 + Route 53) ────────
provider "aws" {
  region = var.aws_region
}

# ── us-east-1 alias — ACM cert must live here for CloudFront
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
