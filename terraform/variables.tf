###############################################################################
# Variables
###############################################################################

variable "aws_region" {
  description = "Primary AWS region for Lambda, SES, and S3."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Apex domain for the site (e.g. awsugmixtli.com)."
  type        = string
  default     = "awsugmixtli.com"
}

variable "to_email" {
  description = "Recipient address for sponsor contact form submissions."
  type        = string
}

variable "from_email" {
  description = "SES-verified sender address (must be in a verified domain/identity)."
  type        = string
}

variable "environment" {
  description = "Deployment environment tag (e.g. production, staging)."
  type        = string
  default     = "production"
}

variable "github_org" {
  description = "GitHub organization that owns the repository."
  type        = string
  default     = "awsugmixtli"
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
  default     = "web"
}

variable "web_acl_id" {
  description = "ARN of a WAFv2 WebACL (must be in us-east-1) to attach to the CloudFront distribution. Leave empty to deploy without WAF — create the WebACL in the AWS Console first, then set this value and re-apply."
  type        = string
  default     = ""
}

variable "cloudfront_price_class" {
  description = "CloudFront price class. PriceClass_All uses all edge locations (recommended with flat pricing — all regions now cost the same)."
  type        = string
  default     = "PriceClass_All"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.cloudfront_price_class)
    error_message = "Must be one of PriceClass_All, PriceClass_200, PriceClass_100."
  }
}
