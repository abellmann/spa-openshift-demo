# Copilot Instructions for Team 2 Demo Application

## Architecture Overview

This is a production-grade SPA with three key components:

**OpenShift Routes + Gateway Pattern**: OpenShift Routes expose the gateway (Nginx) which serves the Angular SPA at `/app1/` and proxies API calls to the backend at `/api/*`.

- **Gateway** (`gateway/nginx.conf`): Serves SPA at `/app1/`, proxies `/api/*` to backend via Kubernetes DNS (`backend-team2:8080`), no root redirect (multi-app ready)
- **Backend** (Spring Boot 3.2, Java 17): RESTful API with health endpoints at `/actuator/health`, no CORS (same-origin via routes)
- **Frontend** (Angular): SPA built with `--base-href /app1/`, served by Nginx with asset caching

Data flow: Browser → Route → Nginx:8080 → (static files at /app1/ OR proxied to Java:8080 at /api/)

## Development Environment Setup

### Using Devbox (Recommended)

The project includes `devbox.json` for consistent development environments. All required tools (Java 17, Maven, Node.js, Docker, kubectl) are automatically installed:

```bash
# Install Devbox (one-time)
curl -fsSL https://get.jetpack.io/devbox | bash

# Enter development environment
devbox shell

# All tools are now available with correct versions
java -version    # Java 17
mvn --version    # Maven
node --version   # Node.js 18
docker --version # Docker
kubectl --version # kubectl
```

See [DEVBOX_SETUP.md](../DEVBOX_SETUP.md) for detailed instructions and troubleshooting.

### Prerequisites (Without Devbox)
- Java 17
- Maven 3.9+
- Node.js 20+ and npm
- Docker or Podman
- kubectl
- Podman Desktop with OpenShift Local (CRC) extension enabled

## Development Setup: OpenShift Local (CRC)

The project uses **OpenShift Local (CRC)** in development to match production environments. Routes handle external access.

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
# Get route URLs
kubectl get routes -n team2-demo
# Visit http://team2-frontend-team2-demo.apps-crc.testing/app1
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
│   ├── frontend-route.yaml
│   ├── api-route.yaml
│   ├── backend-route.yaml
│   └── kustomization.yaml
├── overlays/
│   ├── dev/             # OpenShift Local development
│   │   ├── kustomization.yaml   # 1 replica, Never pull, reduced resources
│   │   └── README.md
│   └── test/            # OpenShift test/production
│       ├── kustomization.yaml   # 2 replicas, Always pull, registry images
│       ├── backend-patch.yaml
│       ├── gateway-patch.yaml
│       ├── network-policy.yaml
│       └── README.md
tests/
└── routes.spec.ts        # TypeScript smoke tests (npm run test:routes)
```

### Key Differences: Dev vs Test

| Aspect | Dev (OpenShift Local) | Test (OpenShift) |
|--------|----------------------|------------------|
| **Replicas** | 1 | 2 |
| **Image Pull** | Never (local) | Always (registry) |
| **Images** | `team2-backend:latest` | `${REGISTRY}/team2-backend:${VERSION}` |
| **Routes** | Yes (auto-generated hosts) | Yes (with TLS) |
| **Profiles** | `kubernetes` | `openshift` |
| **Resources** | Reduced (128Mi/256Mi) | Full (384Mi/768Mi) |
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
2. **CORS in backend**: Not required now; traffic is same-origin via gateway/routes
3. **Environment profiles**: Backend respects `SPRING_PROFILES_ACTIVE` (kubernetes in dev, openshift in test)
4. **Kubernetes DNS**: Internal service communication uses `<service-name>:<port>`: `backend-team2:8080` (defined in K8s Services)
5. **Non-root execution**: All containers run as non-root; Nginx runs as `nginx`, Java as `spring`
6. **Image pull policy**: Dev uses `IfNotPresent` (local images), Test uses `Always` (registry images)

## Testing

**Route smoke tests** (TypeScript):
```bash
npm install
npm run test:routes
```

Tests verify:
- Route accessibility and redirects
- Static asset loading
- API endpoint availability (3 routes)
- Security headers
- Pod readiness
- No internal port exposure in redirects

## Development Commands

```bash
# Start development (builds images and deploys to OpenShift Local)
./dev.sh

# View manifests that will be applied
kubectl apply -k k8s/overlays/dev --dry-run=client -o yaml

# Interactive debugging
kubectl exec -it -n team2-demo deployment/backend-team2 -- /bin/bash
kubectl exec -it -n team2-demo deployment/gateway-team2 -- /bin/sh

# Build images and load into CRC
docker build --load -f docker/Dockerfile.backend -t team2-backend:latest .
docker build --load -f docker/Dockerfile.gateway -t team2-gateway:latest .
./load-images-crc.sh

# Build production images
export REGISTRY="your-registry.io/team2"
export VERSION="0.0.1"
./build.sh

# Run smoke tests
npm run test:routes

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

1. **OpenShift Local development**: dev.sh requires CRC running with OpenShift Local
2. **Multi-app ready**: No root redirect—apps accessed via explicit paths (`/app1/`, `/app2/`)
3. **CORS removed**: Not required—traffic is same-origin via gateway routes
4. **No hardcoded UIDs**: Base manifests use `runAsNonRoot: true` only; OpenShift auto-assigns safe UIDs
5. **Routes in base**: All 3 routes (frontend, api, backend) defined in base manifests
6. **Port exposure**: `port_in_redirect off` prevents internal :8080 appearing in redirects
7. **Image loading**: Dev uses `./load-images-crc.sh` to pipe Docker images to CRC Podman
8. **Kustomize strategy**: Base + overlays pattern; dev overlay only adds dev-specific patches (1 replica, Never pull, reduced resources)

## Devbox Package Reference (AI Agent Reference)

### Verified Packages in devbox.json

All packages verified against Nixpkgs unstable (25.11). Use `package:version` syntax for version-specific packages.

| Package | Name in devbox.json | Current Version | Notes |
|---------|-------------------|-----------------|-------|
| Java | `openjdk17` | 17.0.17+10 | OpenJDK 17 LTS; other options: `openjdk11`, `openjdk21` |
| Maven | `maven@3.9` | 3.9.12 | Version pinned to 3.9.x for stability |
| Node.js | `nodejs_20` | 20.19.6 | LTS version (18 is EOL); alternatives: `nodejs_22` (22.21.1), `nodejs` (latest) |
| Docker | `docker` | Latest | Container runtime |
| kubectl | `kubectl` | Latest | Kubernetes CLI |
| Git | `git` | Latest | Version control |
| curl | `curl` | Latest | HTTP client |
| jq | `jq` | Latest | JSON processor |
| yq | `yq` | Latest | YAML processor |
| gnumake | `gnumake` | Latest | Build automation |
| vim | `vim` | Latest | Text editor |

### Package Syntax Notes

- **Without version**: `"docker"` → Latest available version
- **With version**: `"maven@3.9"` → Specific version (3.9.x); major.minor pins to latest patch
- **Node.js versions**: Use `nodejs_18`, `nodejs_20`, `nodejs_22`, `nodejs_25`, or `nodejs` (latest)
- All versions verified in Nixpkgs unstable channel


