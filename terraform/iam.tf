###############################################################################
# IAM — Lambda execution role with least-privilege SES permission
###############################################################################

# ── Trust policy: allow Lambda to assume this role ────────
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    sid     = "AllowLambdaAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "mixtli-sponsor-form-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Environment = var.environment
  }
}

# ── CloudWatch Logs ───────────────────────────────────────
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ── SES SendEmail (scoped to FROM_EMAIL identity only) ────
data "aws_iam_policy_document" "lambda_ses" {
  statement {
    sid    = "AllowSESSendEmail"
    effect = "Allow"

    actions = ["ses:SendEmail", "ses:SendRawEmail"]

    # Lock down to the specific verified sender identity
    resources = [
      "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}:identity/${var.domain_name}",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_ses" {
  name   = "ses-send-email"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_ses.json
}

# Helper: current AWS account ID
data "aws_caller_identity" "current" {}
