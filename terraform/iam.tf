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

###############################################################################
# IAM — ICS Sync Lambda execution role with SSM read/write permission
###############################################################################

resource "aws_iam_role" "ics_sync" {
  name               = "mixtli-ics-sync-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ics_sync_basic_execution" {
  role       = aws_iam_role.ics_sync.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "ics_sync_ssm" {
  # Read the GitHub PAT and read/write the event fingerprint state
  statement {
    sid    = "AllowSSMReadWrite"
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter",
    ]
    resources = [
      aws_ssm_parameter.github_pat.arn,
      aws_ssm_parameter.ics_sync_state.arn,
    ]
  }

  # Decrypt SSM SecureString parameters (using the AWS-managed SSM key)
  statement {
    sid     = "AllowSSMDecrypt"
    effect  = "Allow"
    actions = ["kms:Decrypt"]

    # Wildcard is required for the AWS-managed key; scoped to SSM via condition
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ics_sync_ssm" {
  name   = "ssm-ics-sync"
  role   = aws_iam_role.ics_sync.id
  policy = data.aws_iam_policy_document.ics_sync_ssm.json
}

###############################################################################
# IAM — GitHub Actions OIDC deploy role (no long-lived keys)
###############################################################################

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

resource "aws_iam_role" "github_deploy" {
  name        = "mixtli-github-deploy"
  description = "Assumed by GitHub Actions (${var.github_org}/${var.github_repo}) to deploy awsugmixtli.com"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = ["sts:AssumeRoleWithWebIdentity", "sts:TagSession"]
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Allow main-branch pushes/schedule/workflow_dispatch AND
          # repository_dispatch (which omits the ref in the sub claim)
          "token.actions.githubusercontent.com:sub" = [
            "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
            "repo:${var.github_org}/${var.github_repo}:",
          ]
        }
      }
    }]
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "github_deploy" {
  name = "mixtli-deploy-policy"
  role = aws_iam_role.github_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Sync"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          aws_s3_bucket.site.arn,
          "${aws_s3_bucket.site.arn}/*",
        ]
      },
      {
        Sid      = "CloudFrontInvalidate"
        Effect   = "Allow"
        Action   = "cloudfront:CreateInvalidation"
        Resource = aws_cloudfront_distribution.site.arn
      },
      {
        Sid    = "LambdaDeploy"
        Effect = "Allow"
        Action = "lambda:UpdateFunctionCode"
        Resource = [
          aws_lambda_function.sponsor_form.arn,
          aws_lambda_function.ics_sync.arn,
        ]
      },
    ]
  })
}
