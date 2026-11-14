###############################################################################
# Lambda — Sponsor contact form handler
###############################################################################

# Zip the Python source file from the sibling lambda/ directory
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../lambda/index.py"
  output_path = "${path.module}/../lambda/index.zip"
}

resource "aws_lambda_function" "sponsor_form" {
  function_name = "mixtli-sponsor-form"
  description   = "Handles sponsor contact form submissions and sends email via SES"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.12"
  handler = "index.handler"
  role    = aws_iam_role.lambda.arn
  timeout = 15 # seconds

  environment {
    variables = {
      TO_EMAIL   = var.to_email
      FROM_EMAIL = var.from_email
      # Shared secret injected by CloudFront on every proxied request.
      # The Lambda rejects calls that lack this value (direct URL access).
      ORIGIN_SECRET = random_password.origin_secret.result
    }
  }

  tags = {
    Name        = "mixtli-sponsor-form"
    Environment = var.environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.lambda,
  ]
}

# ── Function URL ──────────────────────────────────────────
# CORS is intentionally omitted here: the browser never calls this URL
# directly — all requests are proxied through the CloudFront distribution
# at /api/sponsor, making them same-origin from the browser's perspective.
# The raw Lambda URL is protected by the x-origin-secret header check
# in the Lambda handler itself.
resource "aws_lambda_function_url" "sponsor_form" {
  function_name      = aws_lambda_function.sponsor_form.function_name
  authorization_type = "NONE"
}

# ── CloudWatch Log Group (explicit so retention is set) ───
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/mixtli-sponsor-form"
  retention_in_days = 30

  tags = {
    Environment = var.environment
  }
}
