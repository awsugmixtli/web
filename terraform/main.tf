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
#   • IAM role & policy for the Lambda (least privilege)
#   • CloudWatch Log Group for the Lambda
###############################################################################

terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.48"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.8"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }

  backend "s3" {
    bucket = "mixtli-tf-state"
    key    = "awsugmixtli/terraform.tfstate"
    region = "us-east-1"
  }
}

# ── Primary region (Lambda + SES + S3 + Route 53) ────────
provider "aws" {
  region = var.aws_region
}
