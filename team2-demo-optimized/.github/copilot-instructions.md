# Copilot Instructions for Team 2 Demo Application

## Architecture Overview

This is a production-grade SPA with three key components:

**Unified Gateway Pattern**: A single Nginx container (port 8080) serves the Angular SPA AND proxies API calls to the backend. The gateway is the only exposed service in Kubernetes.

- **Gateway** (`gateway/nginx.conf`): Routes `/` to Angular static files, `/api/*` to backend via Kubernetes DNS (`backend-team2:8080`)
- **Backend** (Spring Boot 3.2, Java 17): RESTful API with health endpoints at `/actuator/health`
- **Frontend** (Angular): SPA served by Nginx with asset caching (1-year expires for js/css/images)

Data flow: Browser → Nginx:8080 → (static files OR proxied to Java:8080)

## Development Setup: Kubernetes (Rancher Desktop)

The project now uses **Kubernetes in development** to match production environments. Docker Compose is no longer used.

### Prerequisites
- Rancher Desktop installed with Kubernetes enabled
- kubectl configured for Rancher context

### Local Development Workflow

**Start development environment:**
```bash
./dev.sh
```

This script:
1. Verifies Kubernetes is running
2. Builds `team2-backend:latest` and `team2-gateway:latest` Docker images
3. Deploys to `team2-demo` namespace using `k8s/overlays/dev`
4. Waits for pods to become ready
5. Shows access instructions

**Access the application:**
```bash
kubectl port-forward -n team2-demo svc/gateway-team2 3000:8080
# Visit http://localhost:3000
```

**Monitor deployment:**
```bash
kubectl get pods -n team2-demo -w
kubectl logs -n team2-demo -f deployment/gateway-team2
kubectl logs -n team2-demo -f deployment/backend-team2
```

**Cleanup:**
```bash
kubectl delete -k k8s/overlays/dev
```

## Kubernetes Configuration (Kustomize)

The project uses **Kustomize overlays** for environment-specific configuration:

### Directory Structure

```
k8s/
├── base/                 # Common manifests (both dev and test)
│   ├── namespace.yaml
│   ├── backend-deployment.yaml
│   ├── gateway-deployment.yaml
│   └── kustomization.yaml
├── overlays/
│   ├── dev/             # Rancher Desktop development
│   │   ├── kustomization.yaml   # 1 replica, IfNotPresent pull, NodePort
│   │   ├── gateway-service-patch.yaml
│   │   └── README.md
│   └── test/            # OpenShift test/production
│       ├── kustomization.yaml   # 2 replicas, Always pull, registry images
│       ├── backend-patch.yaml
│       ├── gateway-patch.yaml
│       ├── route.yaml
│       ├── network-policy.yaml
│       └── README.md
```

### Key Differences: Dev vs Test

| Aspect | Dev (Rancher) | Test (OpenShift) |
|--------|---------------|-----------------|
| **Replicas** | 1 | 2 |
| **Image Pull** | IfNotPresent | Always |
| **Images** | `team2-backend:latest` | `${REGISTRY}/team2-backend:${VERSION}` |
| **Service Type** | NodePort (30080) | ClusterIP + Route |
| **Profiles** | `kubernetes` | `openshift` |
| **Network Policy** | None | Yes (namespace ingress) |

### Deploy to OpenShift (Test/Prod)

```bash
export REGISTRY="your-registry.io/team2"
export VERSION="0.0.1"

# Build and push images
docker build -f docker/Dockerfile.backend -t ${REGISTRY}/team2-backend:${VERSION} .
docker build -f docker/Dockerfile.gateway -t ${REGISTRY}/team2-gateway:${VERSION} .
docker push ${REGISTRY}/team2-backend:${VERSION}
docker push ${REGISTRY}/team2-gateway:${VERSION}

# Deploy
kubectl apply -k k8s/overlays/test

# Watch deployment
kubectl get pods -n team2-demo -w

# Get route
kubectl get route -n team2-demo
```

## Environment Profiles

Backend respects `SPRING_PROFILES_ACTIVE`:
- **kubernetes** (Rancher development): Used by `k8s/overlays/dev`
- **openshift** (Test/Prod): Used by `k8s/overlays/test`

## Production Build

**Build Images** (`./build.sh`):
- Sets `REGISTRY` and `VERSION` env vars
- Multi-stage builds minimize images: Maven layers cached by `dependency:go-offline`
- Produces tagged images: `${REGISTRY}/team2-backend:${VERSION}` and `${REGISTRY}/team2-gateway:${VERSION}`

## Key Files & Patterns

| File | Purpose | Key Pattern |
|------|---------|------------|
| `k8s/base/kustomization.yaml` | Common base config | All resources shared between dev/test |
| `k8s/overlays/dev/kustomization.yaml` | Dev environment setup | 1 replica, local images, IfNotPresent |
| `k8s/overlays/test/kustomization.yaml` | OpenShift test setup | 2 replicas, registry images, Always pull |
| `gateway/nginx.conf` | Routing, security headers, proxy config | `try_files $uri $uri/ /index.html` for SPA fallback |
| `backend/pom.xml` | Maven config, Spring Boot 3.2 parent | Java 17 target, Spring Actuator enabled |
| `docker/Dockerfile.*` | Multi-stage builds | Separate build/runtime stages, non-root USER |

## Critical Conventions

1. **Backend health endpoints**: Always use `/actuator/health/readiness` (K8s probes) and `/actuator/health/liveness` (both Docker and K8s)
2. **CORS in backend**: `@CrossOrigin(origins = "*")` on controllers—note comment to restrict in production
3. **Environment profiles**: Backend respects `SPRING_PROFILES_ACTIVE` (kubernetes in dev, openshift in test)
4. **Kubernetes DNS**: Internal service communication uses `<service-name>:<port>`: `backend-team2:8080` (defined in K8s Services)
5. **Non-root execution**: All containers run as non-root; Nginx runs as `nginx`, Java as `spring`
6. **Image pull policy**: Dev uses `IfNotPresent` (local images), Test uses `Always` (registry images)

## Development Commands

```bash
# Start development (builds images and deploys to Rancher K8s)
./dev.sh

# View manifests that will be applied
kubectl apply -k k8s/overlays/dev --dry-run=client -o yaml

# Interactive debugging
kubectl exec -it -n team2-demo deployment/backend-team2 -- /bin/bash
kubectl exec -it -n team2-demo deployment/gateway-team2 -- /bin/sh

# Build images only (without deploying)
docker build -f docker/Dockerfile.backend -t team2-backend:latest .
docker build -f docker/Dockerfile.gateway -t team2-gateway:latest .

# Build production images
export REGISTRY="your-registry.io/team2"
export VERSION="0.0.1"
./build.sh

# Deploy to OpenShift (after pushing images)
kubectl apply -k k8s/overlays/test
```

## Common Modification Points

- **Add backend endpoint**: Create method in `HelloController.java`, update routing if needed
- **Change frontend build**: Modify `frontend/angular.json` (output path must match Dockerfile.gateway COPY target `/build/dist/team2-frontend/`)
- **Adjust resource limits**: Edit `resources.requests|limits` in `k8s/base/backend-deployment.yaml` or `gateway-deployment.yaml`
- **Update Nginx behavior**: Edit `gateway/nginx.conf`, rebuild with `docker build -f docker/Dockerfile.gateway -t team2-gateway:latest .`
- **Add OpenShift-specific config**: Add patches in `k8s/overlays/test/` instead of modifying base files

## Dependencies & Versions

- Java 17 (eclipse-temurin:17.0.17_10-jre base image)
- Spring Boot 3.2.0 (parent in pom.xml)
- Angular 18+ (check `frontend/package.json`)
- Nginx 1.25 Alpine (gateway Dockerfile)
- Node 18 Alpine (frontend build stage)
- Kustomize v5+ (included in kubectl 1.26+)

## Known Constraints & Decisions

1. **Kubernetes development**: dev.sh requires Rancher Desktop K8s enabled
2. **Unified gateway**: No separate ingress controller—all traffic flows through one Nginx pod
3. **CORS permissive**: `origins = "*"` intentional for demo; tighten in production
4. **K8s service name**: Backend K8s Service MUST be named `backend-team2` (hard-coded in `nginx.conf`)
5. **Kustomize strategy**: Base + overlays pattern; overlays override replicas, images, profiles per environment
6. **Image availability**: Dev overlay requires locally built images; test overlay pulls from registry


