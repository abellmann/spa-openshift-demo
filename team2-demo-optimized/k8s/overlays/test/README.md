# OpenShift Test/Production Setup

## Prerequisites

```bash
# Set registry and version
export REGISTRY="your-registry.io/team2"
export VERSION="0.0.1"

# Build and push images
docker build -f docker/Dockerfile.backend -t ${REGISTRY}/team2-backend:${VERSION} .
docker build -f docker/Dockerfile.gateway -t ${REGISTRY}/team2-gateway:${VERSION} .
docker push ${REGISTRY}/team2-backend:${VERSION}
docker push ${REGISTRY}/team2-gateway:${VERSION}
```

## Deploy to OpenShift

```bash
export REGISTRY="your-registry.io/team2"
export VERSION="0.0.1"

# Deploy with kustomize
kubectl apply -k k8s/overlays/test

# Watch deployment
kubectl get pods -n team2-demo -w

# Get routes
kubectl get routes -n team2-demo
```

## Update Route Hostname

Edit the hostname in `k8s/overlays/test/kustomization.yaml` (patches section) or patch after deployment:

```bash
# Update frontend route
kubectl patch route team2-frontend -n team2-demo -p '{"spec":{"host":"team2-demo.apps.your-cluster.com"}}'

# Update backend route
kubectl patch route team2-backend -n team2-demo -p '{"spec":{"host":"team2-demo.apps.your-cluster.com"}}'
```

## Cleanup

```bash
kubectl delete -k k8s/overlays/test
```

## Configuration

This overlay:
- Uses registry images (`${REGISTRY}/team2-backend:${VERSION}`, `${REGISTRY}/team2-gateway:${VERSION}`)
- Runs 2 replicas for high availability
- Uses `Always` image pull policy
- Creates OpenShift Routes with:
  - Fixed hostname: `team2-demo.apps.your-cluster.com`
  - TLS edge termination
  - Path-based routing: `/app1` (frontend), `/app1/api` (backend)
- Includes NetworkPolicy for security
