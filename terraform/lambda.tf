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

###############################################################################
# Lambda — ICS sync (weekly EventBridge trigger → S3 JSON)
###############################################################################

data "archive_file" "ics_sync" {
  type        = "zip"
  source_file = "${path.module}/../lambda/ics_sync.py"
  output_path = "${path.module}/../lambda/ics_sync.zip"
}

resource "aws_lambda_function" "ics_sync" {
  function_name = "mixtli-ics-sync"
  description   = "Watches Meetup iCal every 6 h; fires GitHub repository_dispatch on change to trigger Hugo rebuild"

  filename         = data.archive_file.ics_sync.output_path
  source_code_hash = data.archive_file.ics_sync.output_base64sha256

  runtime = "python3.12"
  handler = "ics_sync.handler"
  role    = aws_iam_role.ics_sync.arn
  timeout = 30 # seconds

  environment {
    variables = {
      GITHUB_REPO      = "${var.github_org}/${var.github_repo}"
      GITHUB_SSM_PARAM = aws_ssm_parameter.github_pat.name
      STATE_SSM_PARAM  = aws_ssm_parameter.ics_sync_state.name
    }
  }

  tags = {
    Name        = "mixtli-ics-sync"
    Environment = var.environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.ics_sync_basic_execution,
    aws_cloudwatch_log_group.ics_sync,
  ]
}

# ── SSM parameters ────────────────────────────────────────
# GitHub PAT — set the real value after first apply (lifecycle.ignore_changes
# prevents Terraform from overwriting it on subsequent applies):
#
#   aws ssm put-parameter \
#       --name /mixtli/github-pat \
#       --value "github_pat_XXXX" \
#       --type SecureString --overwrite --region us-east-1
#
# The PAT needs "Actions: write" (fine-grained) or "repo" scope (classic)
# on the ${var.github_org}/${var.github_repo} repository.
resource "aws_ssm_parameter" "github_pat" {
  name        = "/mixtli/github-pat"
  description = "GitHub PAT for ics_sync Lambda → repository_dispatch rebuild trigger"
  type        = "SecureString"
  value       = "CHANGE_ME_AFTER_APPLY"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name        = "mixtli-github-pat"
    Environment = var.environment
  }
}

# Last-seen iCal event fingerprint — managed entirely by the Lambda at runtime.
resource "aws_ssm_parameter" "ics_sync_state" {
  name        = "/mixtli/ics-sync-state"
  description = "Last known iCal event fingerprint (uid|start ISO); updated by ics_sync Lambda"
  type        = "String"
  value       = "init"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name        = "mixtli-ics-sync-state"
    Environment = var.environment
  }
}

# ── CloudWatch Log Group ──────────────────────────────────
resource "aws_cloudwatch_log_group" "ics_sync" {
  name              = "/aws/lambda/mixtli-ics-sync"
  retention_in_days = 30

  tags = {
    Environment = var.environment
  }
}

# ── EventBridge rule: every 6 hours ──────────────────────
# Runs at 00:00, 06:00, 12:00, 18:00 UTC.
# If Meetup changes, the Lambda fires a repository_dispatch within ~6 hours.
# The GitHub Actions daily cron at 06:00 UTC is an independent safety net.
resource "aws_cloudwatch_event_rule" "ics_sync_schedule" {
  name                = "mixtli-ics-sync-6h"
  description         = "Trigger ICS sync Lambda every 6 hours to detect Meetup changes"
  schedule_expression = "cron(0 */6 * * ? *)"

  tags = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_event_target" "ics_sync" {
  rule      = aws_cloudwatch_event_rule.ics_sync_schedule.name
  target_id = "IcsSyncLambda"
  arn       = aws_lambda_function.ics_sync.arn
}

resource "aws_lambda_permission" "ics_sync_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ics_sync.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ics_sync_schedule.arn
}
