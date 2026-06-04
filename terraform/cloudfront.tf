###############################################################################
# CloudFront — CDN + HTTPS termination for the static site
###############################################################################

# ── Origin secret: CloudFront → Lambda authentication ────────────────────────
resource "random_password" "origin_secret" {
  length  = 32
  special = false
  keepers = {
    version = "1"
  }
}

# ── Origin Access Control (successor to OAI) ──────────────────────────────────
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.domain_name}-oac"
  description                       = "OAC for ${var.domain_name} S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ── Security headers — CloudFront Function (viewer-response) ──────────────────
# A CloudFront Function is used instead of a Response Headers Policy so that
# it works with the flat pricing tier and gives us full control over header
# values, including a tight CSP with upgrade-insecure-requests.
#
# CSP notes for this site:
#   • All assets (fonts, CSS, JS, images) are self-hosted on the same origin.
#   • fetch() calls go to /api/sponsor — same-origin.
#   • YouTube embeds use youtube-nocookie.com (privacy-enhanced mode).
#   • No inline scripts, no eval, no external CDN dependencies.
#   • If you add Cloudflare Turnstile later, append to script-src and frame-src:
#       https://challenges.cloudflare.com
resource "aws_cloudfront_function" "security_headers" {
  name    = "mixtli-security-headers"
  runtime = "cloudfront-js-2.0"
  publish = true
  comment = "Inject security response headers for awsugmixtli.com"

  code = <<-JS
    async function handler(event) {
      const resp = event.response;
      const h    = resp.headers;

      h['strict-transport-security'] = {
        value: 'max-age=63072000; includeSubDomains; preload'
      };
      h['content-security-policy'] = {
        value: [
          "default-src 'none'",
          "script-src 'self'",
          "style-src 'self'",
          "font-src 'self'",
          "img-src 'self'",
          "connect-src 'self'",
          "manifest-src 'self'",
          "frame-src https://www.youtube-nocookie.com",
          "frame-ancestors 'none'",
          "base-uri 'self'",
          "form-action 'self'",
          "upgrade-insecure-requests"
        ].join('; ')
      };
      h['x-content-type-options']        = { value: 'nosniff' };
      h['x-frame-options']               = { value: 'DENY' };
      h['referrer-policy']               = { value: 'strict-origin-when-cross-origin' };
      h['permissions-policy']            = { value: 'camera=(), microphone=(), geolocation=(), payment=(), usb=()' };
      h['cross-origin-opener-policy']    = { value: 'same-origin' };
      h['cross-origin-resource-policy']  = { value: 'same-origin' };

      return resp;
    }
  JS
}

# ── CloudFront distribution ───────────────────────────────────────────────────
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class
  aliases             = [var.domain_name, "www.${var.domain_name}"]
  comment             = "${var.domain_name} static site"
  web_acl_id          = var.web_acl_id != "" ? var.web_acl_id : null

  # ── Origin 1: S3 static site ─────────────────────────────
  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-${var.domain_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  # ── Origin 2: Sponsor form Lambda Function URL ────────────
  origin {
    domain_name = trimsuffix(trimprefix(aws_lambda_function_url.sponsor_form.function_url, "https://"), "/")
    origin_id   = "lambda-sponsor-form"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "x-origin-secret"
      value = random_password.origin_secret.result
    }
  }

  # ── Behavior 1 (ordered): /api/sponsor → Lambda ──────────
  # No security-headers function here — this is a JSON API endpoint,
  # not a page, so CSP and framing headers are not appropriate.
  ordered_cache_behavior {
    path_pattern           = "/api/sponsor"
    target_origin_id       = "lambda-sponsor-form"
    viewer_protocol_policy = "https-only"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    compress = false

    # Managed-CachingDisabled
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    # AllViewerExceptHostHeader
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  # ── Behavior 2 (default): S3 static assets ───────────────
  default_cache_behavior {
    target_origin_id       = "s3-${var.domain_name}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # Managed-CachingOptimized
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    # Inject security headers on every S3-served response
    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.security_headers.arn
    }
  }

  # ── Custom error pages ────────────────────────────────────
  # S3 returns 403 (not 404) for missing objects when using OAC+private bucket.
  # Both map to the Hugo-generated 404.html with a proper 404 status.
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  # ── TLS ──────────────────────────────────────────────────
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.3_2025"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = "${var.domain_name}-cdn"
    Environment = var.environment
  }

  depends_on = [aws_acm_certificate_validation.site]
}
