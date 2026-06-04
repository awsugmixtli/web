###############################################################################
# SES — Email domain identity + DKIM + MAIL FROM
#
# After `terraform apply`, SES will generate DKIM CNAME records.
# They are written to Route 53 automatically by this config.
#
# NOTE: SES starts in Sandbox mode. To send to arbitrary recipients you must
# request production access in the AWS Console:
#   SES → Account Dashboard → "Request production access"
###############################################################################

# ── Domain identity ───────────────────────────────────────
resource "aws_sesv2_email_identity" "domain" {
  email_identity = var.domain_name

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }

  tags = {
    Environment = var.environment
  }
}

# ── DKIM CNAME records in Route 53 ───────────────────────
resource "aws_route53_record" "ses_dkim" {
  count = 3

  zone_id = data.aws_route53_zone.site.zone_id
  name    = "${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 1800
  records = ["${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}

# ── Custom MAIL FROM subdomain (improves deliverability) ──
resource "aws_sesv2_email_identity_mail_from_attributes" "domain" {
  email_identity   = aws_sesv2_email_identity.domain.email_identity
  mail_from_domain = "mail.${var.domain_name}"
}

# MX record for MAIL FROM subdomain
resource "aws_route53_record" "ses_mail_from_mx" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = "mail.${var.domain_name}"
  type    = "MX"
  ttl     = 300
  records = ["10 feedback-smtp.${var.aws_region}.amazonses.com"]
}

# SPF TXT record for MAIL FROM subdomain
resource "aws_route53_record" "ses_mail_from_spf" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = "mail.${var.domain_name}"
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com ~all"]
}

# ── DMARC TXT record (recommended) ───────────────────────
resource "aws_route53_record" "dmarc" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 300
  # p=none: monitor only. Switch to p=quarantine/reject once DKIM is confirmed working.
  records = ["v=DMARC1; p=none; rua=mailto:${var.to_email}"]
}
