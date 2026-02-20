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

variable "route53_zone_id" {
  description = "Route 53 Hosted Zone ID for var.domain_name."
  type        = string
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

variable "cloudfront_price_class" {
  description = "CloudFront price class. PriceClass_100 = US/Europe only (cheapest)."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.cloudfront_price_class)
    error_message = "Must be one of PriceClass_All, PriceClass_200, PriceClass_100."
  }
}
