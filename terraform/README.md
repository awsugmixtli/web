# AWS UG Mixtli — Terraform Infrastructure

This directory contains the Terraform configuration to deploy the full AWS stack for [awsugmixtli.com](https://awsugmixtli.com).

## Architecture

```
Browser
  │  HTTPS
  ▼
CloudFront (CDN + TLS)
  ├── Origin: S3 bucket (static site files) — private, OAC auth
  └── Custom domain: awsugmixtli.com + www.awsugmixtli.com

Route 53
  ├── A / AAAA alias → CloudFront
  ├── ACM DNS validation CNAMEs
  └── SES DKIM CNAMEs + MAIL FROM MX/SPF + DMARC

ACM Certificate (us-east-1)
  └── Covers awsugmixtli.com + www.awsugmixtli.com

Lambda Function URL  ← sponsor contact form POST
  └── Lambda (Python 3.12) → SES → to_email

IAM Role (Lambda)
  └── AWSLambdaBasicExecutionRole + ses:SendEmail (scoped to domain identity)

CloudWatch Logs
  └── /aws/lambda/mixtli-sponsor-form (30-day retention)
```

## Prerequisites

| Requirement | Notes |
|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.7 | `brew install terraform` on macOS |
| AWS CLI configured | `aws configure` or environment variables |
| Route 53 Hosted Zone | Must exist before running `terraform apply` |
| AWS account **out of SES Sandbox** | Required to send email to external recipients — see [Request production access](https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html) |

## Quick Start

```bash
# 1. Clone the repo and enter the terraform directory
cd terraform

# 2. Copy the example vars file and fill in your values
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars

# 3. Initialise providers and modules
terraform init

# 4. Preview what will be created
terraform plan

# 5. Apply (takes ~10 min — CloudFront + ACM validation)
terraform apply
```

## Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `aws_region` | No | `us-east-1` | Primary AWS region |
| `domain_name` | No | `awsugmixtli.com` | Apex domain |
| `route53_zone_id` | **Yes** | — | Hosted Zone ID (find it in the Route 53 console) |
| `to_email` | **Yes** | — | Where sponsor form submissions are delivered |
| `from_email` | **Yes** | — | SES-verified sender address |
| `environment` | No | `production` | Tag applied to all resources |
| `cloudfront_price_class` | No | `PriceClass_100` | `PriceClass_100` (US/EU only), `PriceClass_200`, or `PriceClass_All` |

## Outputs

After `terraform apply` completes, the following values are printed:

| Output | Use |
|---|---|
| `cloudfront_distribution_id` | Used in the deploy script to invalidate the CDN cache |
| `cloudfront_domain` | The raw CloudFront domain (e.g. `d1234abcd.cloudfront.net`) |
| `s3_bucket_name` | Target bucket for `aws s3 sync` |
| `lambda_function_url` | **Paste into `assets/sponsor.js` as `SUBMIT_ENDPOINT`** |
| `ses_identity_arn` | ARN of the SES domain identity |
| `ses_dkim_tokens` | DKIM tokens (automatically written to Route 53) |

## Deploying the Site

Once infrastructure is up, upload the static files and bust the CDN cache:

```bash
# Sync site files to S3 (run from repo root)
aws s3 sync . s3://$(terraform -chdir=terraform output -raw s3_bucket_name) \
  --exclude ".git/*" \
  --exclude "terraform/*" \
  --exclude "lambda/*" \
  --exclude "*.md" \
  --delete

# Invalidate CloudFront cache so visitors see the new version immediately
aws cloudfront create-invalidation \
  --distribution-id $(terraform -chdir=terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

## Updating the Lambda

The Lambda source lives at `../lambda/index.py`. Terraform zips it automatically on every `terraform apply` and only re-deploys when the file hash changes.

```bash
# Edit lambda/index.py, then:
terraform apply
```

## SES Setup Notes

1. **DKIM** — Three CNAME records are created in Route 53 automatically. Verification usually takes a few minutes but can take up to 72 hours.
2. **Sandbox mode** — By default SES only lets you send to verified email addresses. [Request production access](https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html) to lift this restriction.
3. **DMARC policy** — Created with `p=none` (monitor only). Once you confirm email is working correctly, update `ses.tf` to `p=quarantine` or `p=reject`.

## File Structure

```
terraform/
├── main.tf                  # Provider config + Terraform version requirements
├── variables.tf             # Input variable declarations
├── outputs.tf               # Useful values printed after apply
├── s3.tf                    # S3 bucket + OAC bucket policy
├── acm.tf                   # ACM certificate (us-east-1) + DNS validation
├── cloudfront.tf            # CloudFront distribution + OAC
├── route53.tf               # A/AAAA alias records for apex + www
├── ses.tf                   # SES domain identity, DKIM, MAIL FROM, SPF, DMARC
├── iam.tf                   # Lambda execution role + ses:SendEmail policy
├── lambda.tf                # Lambda function + Function URL + CloudWatch log group
├── terraform.tfvars.example # Template — copy to terraform.tfvars and fill in values
└── .gitignore               # Excludes state files, tfvars, and generated zip
```
