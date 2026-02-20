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

# ── Function URL (no auth; CORS limited to our domain) ────
resource "aws_lambda_function_url" "sponsor_form" {
  function_name      = aws_lambda_function.sponsor_form.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["https://${var.domain_name}"]
    allow_methods     = ["POST", "OPTIONS"]
    allow_headers     = ["Content-Type"]
    max_age           = 300
  }
}

# ── CloudWatch Log Group (explicit so retention is set) ───
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/mixtli-sponsor-form"
  retention_in_days = 30

  tags = {
    Environment = var.environment
  }
}
