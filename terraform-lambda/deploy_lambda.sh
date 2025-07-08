#!/bin/bash
set -e

FUNCTION_NAME="terraform-runner"
LAYER_NAME="terraform-layer"
REGION="us-west-2"
ACCOUNT_ID="386503255039"
ROLE_ARN="arn:aws:iam::386503255039:role/lambda-exec-role"

echo "🚀 Publishing Lambda Layer..."

LAYER_ARN=$(aws lambda publish-layer-version \
  --layer-name "$LAYER_NAME" \
  --zip-file fileb://terraform-layer.zip \
  --compatible-runtimes python3.11 \
  --region "$REGION" \
  --query 'LayerVersionArn' --output text)

echo "✅ Layer published: $LAYER_ARN"

echo "📦 Zipping lambda_function.py..."
zip -j lambda.zip lambda_function.py

echo "🔧 Deploying Lambda function..."

aws lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --runtime python3.11 \
  --role "$ROLE_ARN" \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://lambda.zip \
  --layers "$LAYER_ARN" \
  --timeout 120 \
  --region "$REGION" && echo "✅ Lambda created!" || {

  echo "🔄 Function exists, updating..."
  aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --zip-file fileb://lambda.zip \
    --region "$REGION"

  aws lambda update-function-configuration \
    --function-name "$FUNCTION_NAME" \
    --layers "$LAYER_ARN" \
    --region "$REGION"

  echo "✅ Lambda updated!"
}
