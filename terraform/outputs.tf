###############################################################################
# Outputs
###############################################################################

output "cloudfront_domain" {
  description = "CloudFront distribution domain name (e.g. d1234abcd.cloudfront.net)."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — needed to invalidate the cache after deploys."
  value       = aws_cloudfront_distribution.site.id
}

output "s3_bucket_name" {
  description = "S3 bucket name for uploading the static site files."
  value       = aws_s3_bucket.site.bucket
}

output "lambda_function_url" {
  description = "Raw Lambda Function URL (internal — traffic is proxied via CloudFront at /api/sponsor). Do NOT use this directly in frontend code."
  value       = aws_lambda_function_url.sponsor_form.function_url
}

output "ses_identity_arn" {
  description = "ARN of the SES domain identity."
  value       = aws_sesv2_email_identity.domain.arn
}

output "deploy_role_arn" {
  description = "Set as AWS_DEPLOY_ROLE_ARN in GitHub Actions repository variables."
  value       = aws_iam_role.github_deploy.arn
}

output "ses_dkim_tokens" {
  description = "DKIM tokens written to Route 53. Verify status in SES console."
  value       = aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens
}
