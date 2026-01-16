# Development Setup with OpenShift Local

## Prerequisites

```bash
# Verify OpenShift Local cluster is running
kubectl cluster-info

# Build images locally
docker build -f docker/Dockerfile.backend -t team2-backend:latest .
docker build -f docker/Dockerfile.gateway -t team2-gateway:latest .
```

## Deploy to OpenShift Local

```bash
# Deploy dev environment
kubectl apply -k k8s/overlays/dev

# Watch deployment
kubectl get pods -n team2-demo -w

# Get route URLs
kubectl get routes -n team2-demo
```

Access routes:
- **Frontend:** `/app1` (auto-generated hostname by OpenShift Local)
- **Backend API:** `/app1/api` (auto-generated hostname by OpenShift Local)

## Cleanup

```bash
kubectl delete -k k8s/overlays/dev
```

## Configuration

This overlay:
- Uses local images (`team2-backend:latest`, `team2-gateway:latest`)
- Runs single replica (faster development iteration)
- Uses `IfNotPresent` image pull policy
- Creates OpenShift Routes with auto-generated hostnames
- No TLS (HTTP only for local dev)
