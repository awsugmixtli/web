###############################################################################
# Terraform import blocks — pre-existing AWS resources
# These resources were created manually before Terraform managed the stack.
# Run: terraform init && terraform plan  (apply creates the rest)
###############################################################################

# ── S3 ───────────────────────────────────────────────────────────────────────
# Bucket name is "awsugmixtli" (not "awsugmixtli.com" — created manually)

import {
  to = aws_s3_bucket.site
  id = "awsugmixtli"
}

import {
  to = aws_s3_bucket_public_access_block.site
  id = "awsugmixtli"
}

import {
  to = aws_s3_bucket_versioning.site
  id = "awsugmixtli"
}

import {
  to = aws_s3_bucket_policy.site
  id = "awsugmixtli"
}

# ── CloudFront ────────────────────────────────────────────────────────────────

import {
  to = aws_cloudfront_distribution.site
  id = "EBLH1N7I9JJYX"
}

import {
  to = aws_cloudfront_origin_access_control.site
  id = "E37DYIV5SFUHPY"
}

# ── ACM certificate ───────────────────────────────────────────────────────────

import {
  to = aws_acm_certificate.site
  id = "arn:aws:acm:us-east-1:852731643316:certificate/04120e3a-ca08-41e1-862c-86abf673d741"
}

# ── Route 53 records ──────────────────────────────────────────────────────────
# Zone Z00609693DTT7PDQ5UZW5 (awsugmixtli.com) was created externally.
# Managed by the data source in route53.tf — no import needed for the zone.

import {
  to = aws_route53_record.apex_a
  id = "Z00609693DTT7PDQ5UZW5_awsugmixtli.com_A"
}

import {
  to = aws_route53_record.apex_aaaa
  id = "Z00609693DTT7PDQ5UZW5_awsugmixtli.com_AAAA"
}

import {
  to = aws_route53_record.www_cname
  id = "Z00609693DTT7PDQ5UZW5_www.awsugmixtli.com_CNAME"
}

# ACM validation CNAME — allow_overwrite = true; imported so apply is idempotent.
# Both domain_validation_options keys share the same physical Route 53 record.
import {
  to = aws_route53_record.acm_validation["awsugmixtli.com"]
  id = "Z00609693DTT7PDQ5UZW5__60082b7cadeaa33f1a8bdf35b55f3d95.awsugmixtli.com._CNAME"
}

import {
  to = aws_route53_record.acm_validation["*.awsugmixtli.com"]
  id = "Z00609693DTT7PDQ5UZW5__60082b7cadeaa33f1a8bdf35b55f3d95.awsugmixtli.com._CNAME"
}

# SES records (exist; import to avoid recreation)
import {
  to = aws_route53_record.dmarc
  id = "Z00609693DTT7PDQ5UZW5__dmarc.awsugmixtli.com_TXT"
}

import {
  to = aws_route53_record.ses_dkim[0]
  id = "Z00609693DTT7PDQ5UZW5_roa76igxavknzsx5bjuvm3vrtddmcc77._domainkey.awsugmixtli.com_CNAME"
}

import {
  to = aws_route53_record.ses_dkim[1]
  id = "Z00609693DTT7PDQ5UZW5_dtmrepn5frvfxcozph4zg2toolooptug._domainkey.awsugmixtli.com_CNAME"
}

import {
  to = aws_route53_record.ses_dkim[2]
  id = "Z00609693DTT7PDQ5UZW5_za5thvmhxlpopjkdc4ynhbkfp4wsmtj4._domainkey.awsugmixtli.com_CNAME"
}

import {
  to = aws_route53_record.ses_mail_from_mx
  id = "Z00609693DTT7PDQ5UZW5_ses.awsugmixtli.com_MX"
}

import {
  to = aws_route53_record.ses_mail_from_spf
  id = "Z00609693DTT7PDQ5UZW5_ses.awsugmixtli.com_TXT"
}

# ── SES ───────────────────────────────────────────────────────────────────────

import {
  to = aws_sesv2_email_identity.domain
  id = "awsugmixtli.com"
}

import {
  to = aws_sesv2_email_identity_mail_from_attributes.domain
  id = "awsugmixtli.com"
}
