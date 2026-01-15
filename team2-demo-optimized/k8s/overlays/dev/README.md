# Development Setup with Kubernetes (Rancher Desktop)

## Prerequisites

```bash
# Verify Rancher Desktop K8s is running
kubectl cluster-info

# Build images locally (must be done before deploying to Rancher)
docker build -f docker/Dockerfile.backend -t team2-backend:latest .
docker build -f docker/Dockerfile.gateway -t team2-gateway:latest .
```

## Deploy to Rancher Desktop

```bash
# Deploy dev environment
kubectl apply -k k8s/overlays/dev

# Watch deployment
kubectl get pods -n team2-demo -w

# Port forward for local access
kubectl port-forward -n team2-demo svc/gateway-team2 3000:8080
```

Access at: `http://localhost:3000`

## Cleanup

```bash
kubectl delete -k k8s/overlays/dev
```
