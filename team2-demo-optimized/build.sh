#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${REGISTRY:-your-registry.io/team2}"
VERSION="${VERSION:-0.0.1}"

echo "🔨 Building production images..."
echo "Registry: ${REGISTRY}"
echo "Version: ${VERSION}"
echo ""

# Build backend
echo "📦 Building backend..."
docker build -f docker/Dockerfile.backend \
  -t "${REGISTRY}/team2-backend:${VERSION}" \
  -t "${REGISTRY}/team2-backend:latest" \
  .

# Build gateway (includes frontend)
echo ""
echo "📦 Building gateway with frontend..."
docker build -f docker/Dockerfile.gateway \
  -t "${REGISTRY}/team2-gateway:${VERSION}" \
  -t "${REGISTRY}/team2-gateway:latest" \
  .

echo ""
echo "✅ Build complete!"
echo ""
echo "📤 To push images to registry:"
echo "  docker push ${REGISTRY}/team2-backend:${VERSION}"
echo "  docker push ${REGISTRY}/team2-backend:latest"
echo "  docker push ${REGISTRY}/team2-gateway:${VERSION}"
echo "  docker push ${REGISTRY}/team2-gateway:latest"
echo ""
echo "🚀 Then deploy with:"
echo "  ./deploy.sh"
