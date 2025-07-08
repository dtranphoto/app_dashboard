deploy-frontend:
	@echo "🪣 Creating S3 bucket if not exists..."
	aws s3api head-bucket --bucket monitor-frontend-site 2>/dev/null || \
	aws s3 mb s3://monitor-frontend-site --region us-west-2

	@echo "🌐 Configuring static site hosting..."
	aws s3 website s3://monitor-frontend-site/ --index-document index.html --error-document index.html

	@echo "🔓 Applying public-read bucket policy..."
	printf '%s\n' '{' \
	'"Version": "2012-10-17",' \
	'"Statement": [' \
	'  {' \
	'    "Sid": "PublicReadGetObject",' \
	'    "Effect": "Allow",' \
	'    "Principal": "*",' \
	'    "Action": "s3:GetObject",' \
	'    "Resource": "arn:aws:s3:::monitor-frontend-site/*"' \
	'  }' \
	']' \
	'}' > tmp_policy.json
	aws s3api put-bucket-policy --bucket monitor-frontend-site --policy file://tmp_policy.json
	rm tmp_policy.json

	@echo "🚀 Uploading index.html and companies.json to S3..."
	aws s3 cp index.html s3://monitor-frontend-site/
	aws s3 cp companies.json s3://monitor-frontend-site/

	@echo "✅ Deployed: http://monitor-frontend-site.s3-website-us-west-2.amazonaws.com"
