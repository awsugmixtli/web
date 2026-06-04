# ─────────────────────────────────────────────────────────────────────────────
# AWS UG Mixtli — Build & Deploy
#
# Local full deploy:
#   make all BUCKET=awsugmixtli.com DISTRIBUTION_ID=EXXXXXXXXXXXXXX
#
# CI (GitHub Actions) calls build, sync, and invalidate as separate steps.
# Get DISTRIBUTION_ID from: cd terraform && terraform output -raw cloudfront_distribution_id
# ─────────────────────────────────────────────────────────────────────────────

BUCKET            ?= awsugmixtli.com
DISTRIBUTION_ID   ?= $(error Set DISTRIBUTION_ID or run: export DISTRIBUTION_ID=$$(cd terraform && terraform output -raw cloudfront_distribution_id))
DIST              ?= dist

AWS_FLAGS := --region us-east-1

.PHONY: all build deploy sync invalidate

# Full local deploy: build → sync → invalidate
all: build sync invalidate

# Hugo builds, minifies, fingerprints, and injects SRI — no Node needed.
build:
	hugo --minify

# CI entry point: sync pre-built dist/ artifact then invalidate
deploy: sync invalidate

sync:
	@echo "→ Uploading HTML (no-cache)"
	aws s3 sync $(DIST)/ s3://$(BUCKET)/ $(AWS_FLAGS) \
		--exclude "*" \
		--include "*.html" \
		--cache-control "no-cache" \
		--delete

	@echo "→ Uploading CSS + JS (fingerprinted → immutable, 1 year)"
	aws s3 sync $(DIST)/css/ s3://$(BUCKET)/css/ $(AWS_FLAGS) \
		--cache-control "public, max-age=31536000, immutable"
	aws s3 sync $(DIST)/js/ s3://$(BUCKET)/js/ $(AWS_FLAGS) \
		--cache-control "public, max-age=31536000, immutable"

	@echo "→ Uploading fonts (immutable, 1 year)"
	aws s3 sync $(DIST)/assets/ s3://$(BUCKET)/assets/ $(AWS_FLAGS) \
		--exclude "*" \
		--include "*.woff2" \
		--cache-control "public, max-age=31536000, immutable"

	@echo "→ Uploading images + icons (1 week)"
	aws s3 sync $(DIST)/assets/ s3://$(BUCKET)/assets/ $(AWS_FLAGS) \
		--exclude "*" \
		--include "*.avif" \
		--include "*.png" \
		--include "*.svg" \
		--include "*.ico" \
		--include "*.webp" \
		--include "*.jpg" \
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
