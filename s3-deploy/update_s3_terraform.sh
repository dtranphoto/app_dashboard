#!/bin/bash
set -e

BUCKET="monitor-frontend-site"
DEST="terraform"

echo "🧹 Syncing ../terraform (excluding .terraform and lockfile)..."
aws s3 sync ../terraform s3://$BUCKET/$DEST --dryrun \
  --exclude ".terraform/*" \
  --exclude ".terraform/**" \
  --exclude ".terraform.lock.hcl"

echo "📤 Uploading index.html and companies.json..."
aws s3 cp index.html s3://$BUCKET/
aws s3 cp companies.json s3://$BUCKET/

echo "✅ All files synced to s3://$BUCKET/"


