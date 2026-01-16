#!/bin/bash
set -e

echo "🔍 Checking if images exist in Docker..."
docker images | grep -E "team2-(backend|gateway)" || {
  echo "❌ Images not found in Docker. Please run:"
  echo "   docker build -f docker/Dockerfile.backend -t team2-backend:latest ."
  echo "   docker build -f docker/Dockerfile.gateway -t team2-gateway:latest ."
  exit 1
}

echo "💾 Saving Docker images to tar files..."
mkdir -p /tmp/crc-images
docker save team2-backend:latest -o /tmp/crc-images/team2-backend.tar
docker save team2-gateway:latest -o /tmp/crc-images/team2-gateway.tar

echo "🔧 Switching to CRC Podman environment..."
eval $(crc podman-env)

echo "📦 Loading images into CRC Podman..."
podman load -i /tmp/crc-images/team2-backend.tar
podman load -i /tmp/crc-images/team2-gateway.tar

echo "🔄 Restarting deployments..."
kubectl rollout restart deployment backend-team2 gateway-team2 -n team2-demo

echo "⏳ Waiting for pods to be ready..."
kubectl rollout status deployment backend-team2 -n team2-demo --timeout=120s
kubectl rollout status deployment gateway-team2 -n team2-demo --timeout=120s

echo "✅ Images loaded and deployments restarted!"
echo ""
echo "📋 Pod status:"
kubectl get pods -n team2-demo

echo ""
echo "🌐 Routes:"
kubectl get routes -n team2-demo

# Cleanup
rm -rf /tmp/crc-images
