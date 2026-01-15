# Quick Reference: Kubernetes Development

## Start Development
```bash
./dev.sh
```

## Access Application
```bash
kubectl port-forward -n team2-demo svc/gateway-team2 3000:8080
# http://localhost:3000
```

## Monitor
```bash
# Watch pods
kubectl get pods -n team2-demo -w

# View logs
kubectl logs -n team2-demo -f deployment/gateway-team2
kubectl logs -n team2-demo -f deployment/backend-team2

# Get pod details
kubectl describe pod -n team2-demo <pod-name>
```

## Debug
```bash
# Shell into backend
kubectl exec -it -n team2-demo deployment/backend-team2 -- /bin/bash

# Shell into gateway
kubectl exec -it -n team2-demo deployment/gateway-team2 -- /bin/sh

# Check health
kubectl exec -n team2-demo deployment/backend-team2 -- curl http://localhost:8080/actuator/health
```

## Build & Deploy
```bash
# Build images locally
docker build -f docker/Dockerfile.backend -t team2-backend:latest .
docker build -f docker/Dockerfile.gateway -t team2-gateway:latest .

# Deploy to Rancher
kubectl apply -k k8s/overlays/dev

# Dry run (preview manifests)
kubectl apply -k k8s/overlays/dev --dry-run=client -o yaml
```

## Cleanup
```bash
# Remove dev deployment
kubectl delete -k k8s/overlays/dev

# Remove namespace
kubectl delete namespace team2-demo
```

## Production
```bash
export REGISTRY="your-registry.io/team2"
export VERSION="0.0.1"

# Build & push
./build.sh
docker push ${REGISTRY}/team2-backend:${VERSION}
docker push ${REGISTRY}/team2-gateway:${VERSION}

# Deploy to OpenShift
kubectl apply -k k8s/overlays/test

# Get route
kubectl get route -n team2-demo
```

## Manifest Structure
```
k8s/base/                     # Common for both dev & test
├── namespace.yaml
├── backend-deployment.yaml   # Contains Deployment + Service
├── gateway-deployment.yaml   # Contains Deployment + Service
└── kustomization.yaml

k8s/overlays/dev/             # 1 replica, local images
├── kustomization.yaml        # Overrides: 1 replica, IfNotPresent, NodePort
└── README.md

k8s/overlays/test/            # 2 replicas, registry images
├── kustomization.yaml        # Overrides: 2 replicas, Always, env vars
├── route.yaml                # OpenShift Route
├── network-policy.yaml       # Network policies
├── backend-patch.yaml        # Patch: imagePullPolicy, profile
├── gateway-patch.yaml        # Patch: imagePullPolicy
└── README.md
```

## Key Kustomization Fields

**replicas**: Scale pods per environment
**images**: Replace image names/tags (useful for registry/version)
**patches**: Strategic patches for policies, environment vars
**labels**: Add labels to all resources
**resources**: Include additional manifests

## Common Edits

### Change replicas
Edit `k8s/overlays/dev/kustomization.yaml`:
```yaml
replicas:
  - name: backend-team2
    count: 3  # was 1
```

### Change NodePort
Edit `k8s/overlays/dev/kustomization.yaml`:
```yaml
patches:
  - target:
      kind: Service
      name: gateway-team2
    patch: |-
      - op: replace
        path: /spec/ports/0/nodePort
        value: 3000  # was 30080
```

### Add environment variable
Edit `k8s/base/backend-deployment.yaml`:
```yaml
env:
  - name: MY_VAR
    value: "my-value"
```

---

See `.github/copilot-instructions.md` for full details.
