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

# Get route
kubectl get route -n team2-demo
```

## Update Route Hostname

Edit the route in `k8s/overlays/test/route.yaml` or patch after deployment:

```bash
kubectl patch route team2-demo -n team2-demo -p '{"spec":{"host":"team2-demo.apps.your-cluster.com"}}'
```

## Cleanup

```bash
kubectl delete -k k8s/overlays/test
```
