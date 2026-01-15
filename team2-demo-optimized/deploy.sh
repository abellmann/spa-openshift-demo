#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${REGISTRY:-your-registry.io/team2}"
VERSION="${VERSION:-0.0.1}"

echo "Deploying to OpenShift..."
echo "Registry: ${REGISTRY}"
echo "Version: ${VERSION}"

# Apply with kustomize
cd openshift
kustomize edit set image \
  "\${REGISTRY}/team2-backend=${REGISTRY}/team2-backend:${VERSION}" \
  "\${REGISTRY}/team2-gateway=${REGISTRY}/team2-gateway:${VERSION}"

kubectl apply -k .

echo "Deployment initiated!"
echo ""
echo "Check status with:"
echo "  kubectl get pods -n team2-demo"
echo "  kubectl get route -n team2-demo"
