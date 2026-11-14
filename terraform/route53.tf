###############################################################################
# Route 53 — DNS records pointing to CloudFront
###############################################################################

data "aws_route53_zone" "site" {
  name         = var.domain_name
  private_zone = false
}

# A record (IPv4) — apex domain
resource "aws_route53_record" "apex_a" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAA record (IPv6) — apex domain
resource "aws_route53_record" "apex_aaaa" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# www → apex CNAME (matches the existing record in Route 53)
resource "aws_route53_record" "www_cname" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 86400
  records = [var.domain_name]
}
