#!/bin/bash
set -e

echo "🔨 Building Terraform Lambda Layer..."

# Clean up previous artifacts
rm -f terraform-layer.zip
rm -rf layer

# Create layer directory structure
mkdir -p layer/bin

# Download Terraform
echo "⬇️ Downloading Terraform..."
curl -Lo terraform.zip https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip

# Unzip into the layer
unzip -o terraform.zip -d layer/bin
chmod +x layer/bin/terraform

# Package into a zip
echo "📦 Packaging layer..."
cd layer
zip -r ../terraform-layer.zip .
cd ..

# Clean up
rm -rf layer terraform.zip

echo "✅ terraform-layer.zip ready"
