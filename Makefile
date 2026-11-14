# ─────────────────────────────────────────────────────────────────────────────
# AWS UG Mixtli — Build & Deploy
#
# Local full deploy (values auto-read from Terraform state):
#   make all
#
# Override explicitly if needed:
#   make sync BUCKET=awsugmixtli DISTRIBUTION_ID=EXXXXXXXXXXXXXX
#
# CI sets BUCKET and DISTRIBUTION_ID via GitHub Actions repository variables;
# the ?= assignments below are skipped when those are already defined.
# ─────────────────────────────────────────────────────────────────────────────

BUCKET          ?= $(shell terraform -chdir=terraform output -raw s3_bucket_name 2>/dev/null)
DISTRIBUTION_ID ?= $(shell terraform -chdir=terraform output -raw cloudfront_distribution_id 2>/dev/null)
DIST              ?= dist

AWS_FLAGS := --region us-east-1

.PHONY: all build deploy sync invalidate

# Full local deploy: build → sync → invalidate
all: build sync invalidate

# Hugo builds, minifies, fingerprints, and injects SRI — no Node needed.
build:
	hugo --minify --buildFuture

# CI entry point: sync pre-built dist/ artifact then invalidate
deploy: sync invalidate

sync:
	@echo "→ Uploading HTML (no-cache)"
	aws s3 sync $(DIST)/ s3://$(BUCKET)/ $(AWS_FLAGS) \
		--exclude "*" \
		--include "*.html" \
		--cache-control "no-cache" \
		--delete

	@echo "→ Uploading CSS + JS + fonts (fingerprinted/content-hashed → immutable, 1 year)"
	aws s3 sync $(DIST)/ s3://$(BUCKET)/ $(AWS_FLAGS) \
		--exclude "*" \
		--include "*.css" \
		--include "*.js" \
		--include "*.woff2" \
		--cache-control "public, max-age=31536000, immutable"

	@echo "→ Uploading images + icons, whole tree (1 week)"
	aws s3 sync $(DIST)/ s3://$(BUCKET)/ $(AWS_FLAGS) \
		--exclude "*" \
		--include "*.avif" \
		--include "*.png" \
		--include "*.svg" \
		--include "*.ico" \
		--include "*.webp" \
		--include "*.jpg" \
		--include "*.jpeg" \
		--cache-control "public, max-age=604800"

	@echo "→ Uploading webmanifest (1 day)"
	aws s3 sync $(DIST)/assets/ s3://$(BUCKET)/assets/ $(AWS_FLAGS) \
		--exclude "*" \
		--include "*.webmanifest" \
		--cache-control "public, max-age=86400"

	@echo "→ Uploading metadata files (1 day)"
	aws s3 cp $(DIST)/robots.txt s3://$(BUCKET)/robots.txt $(AWS_FLAGS) \
		--cache-control "public, max-age=86400"
	aws s3 cp $(DIST)/sitemap.xml s3://$(BUCKET)/sitemap.xml $(AWS_FLAGS) \
		--cache-control "public, max-age=86400" \
		--content-type "application/xml"
	aws s3 cp $(DIST)/llms.txt s3://$(BUCKET)/llms.txt $(AWS_FLAGS) \
		--cache-control "public, max-age=86400" \
		--content-type "text/plain; charset=utf-8"
	aws s3 cp $(DIST)/.well-known/security.txt s3://$(BUCKET)/.well-known/security.txt $(AWS_FLAGS) \
		--cache-control "public, max-age=86400" \
		--content-type "text/plain; charset=utf-8"

invalidate:
	@echo "→ Invalidating CloudFront distribution $(DISTRIBUTION_ID)"
	aws cloudfront create-invalidation $(AWS_FLAGS) \
		--distribution-id $(DISTRIBUTION_ID) \
		--paths "/*"
	@echo "✓ Done"
