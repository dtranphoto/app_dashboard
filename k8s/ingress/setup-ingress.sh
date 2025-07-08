#!/bin/bash

set -e

echo "🔧 Installing NGINX Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

echo "⏳ Waiting for ingress controller EXTERNAL-IP..."
sleep 10

kubectl get svc ingress-nginx-controller -n ingress-nginx

echo ""
echo "📥 Applying Ingress resource for devops dashboard..."
kubectl apply -f k8-ingress.yaml

echo ""
echo "✅ Ingress setup complete!"
echo "👉 Now point your Route 53 A record (k8.dtinfra.site) to the EXTERNAL-IP above."

