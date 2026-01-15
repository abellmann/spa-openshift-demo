#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${REGISTRY:-your-registry.io/team2}"
VERSION="${VERSION:-0.0.1}"

echo "🚀 Deploying to OpenShift..."
echo "Registry: ${REGISTRY}"
echo "Version: ${VERSION}"

# Build images
echo ""
echo "📦 Building Docker images..."
docker build -f docker/Dockerfile.backend -t "${REGISTRY}/team2-backend:${VERSION}" .
docker build -f docker/Dockerfile.gateway -t "${REGISTRY}/team2-gateway:${VERSION}" .

# Push images
echo ""
echo "📤 Pushing images to registry..."
docker push "${REGISTRY}/team2-backend:${VERSION}"
docker push "${REGISTRY}/team2-gateway:${VERSION}"

# Deploy with kustomize
echo ""
echo "🔧 Deploying to Kubernetes..."
kubectl apply -k k8s/overlays/test

echo ""
echo "✅ Deployment initiated!"
echo ""
echo "📊 Check status with:"
echo "  kubectl get pods -n team2-demo -w"
echo "  kubectl get route -n team2-demo"
