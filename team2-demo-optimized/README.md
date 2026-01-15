# Team 2 Demo Application - Optimized

A production-ready demo application with Spring Boot backend, Angular frontend, and Nginx gateway, deployed with Kubernetes.

## Architecture

```
┌──────────────────────────────────────────┐
│         Kubernetes Cluster               │
│  ┌────────────────────────────────────┐  │
│  │   Gateway Pod (Nginx + SPA)        │  │
│  │   ├─ Port 8080                     │  │
│  │   ├─ Routes: / → Frontend          │  │
│  │   └─ Routes: /api/* → Backend      │  │
│  └─────────────┬──────────────────────┘  │
│                │                         │
│  ┌─────────────▼─────────────────────┐   │
│  │   Backend Pod (Spring Boot)       │   │
│  │   ├─ Port 8080                    │   │
│  │   ├─ /api/hello                   │   │
│  │   └─ /actuator/health/*           │   │
│  └───────────────────────────────────┘   │
└──────────────────────────────────────────┘
```

## Key Features

- **Unified Gateway**: Single Nginx pod serves frontend SPA and proxies backend API
- **Multi-stage Builds**: Optimized Docker images with Maven/npm layer caching
- **Security**: Non-root containers, SecurityContext enforcement, network policies
- **Health Checks**: Readiness and liveness probes for Kubernetes orchestration
- **Resource Management**: CPU and memory requests/limits for proper scheduling
- **Kubernetes Native**: Development uses Rancher Desktop, production uses OpenShift
- **Kustomize Management**: Base + overlays pattern for environment-specific config

## Quick Start

### Prerequisites

- **Rancher Desktop** with Kubernetes enabled (for development)
- **kubectl** configured for your cluster
- **Docker** for building images

### Setup Development Environment

**Recommended: Use Devbox** (see [DEVBOX_QUICK_START.md](./DEVBOX_QUICK_START.md)):
```bash
curl -fsSL https://get.jetpack.io/devbox | bash
devbox shell
```

**Manual setup**: Java 17 • Maven 3.9+ • Node.js 18+ • npm • Docker • kubectl • git

### Local Development (Rancher Desktop)

```bash
# Start development environment (builds images and deploys to Rancher K8s)
./dev.sh

# Port-forward to access the application
kubectl port-forward -n team2-demo svc/gateway-team2 3000:8080

# Visit http://localhost:3000
```

**What `./dev.sh` does:**
1. Verifies Kubernetes is running
2. Builds `team2-backend:latest` and `team2-gateway:latest` Docker images
3. Deploys to `team2-demo` namespace using kustomize dev overlay
4. Waits for pods to become ready

### Monitor the Application

```bash
# Watch pods
kubectl get pods -n team2-demo -w

# View logs
kubectl logs -n team2-demo -f deployment/gateway-team2
kubectl logs -n team2-demo -f deployment/backend-team2

# Shell into a pod
kubectl exec -it -n team2-demo deployment/backend-team2 -- /bin/bash
```

### Cleanup

```bash
kubectl delete -k k8s/overlays/dev
```

## Local Development Workflows

### Backend Development (Spring Boot)

```bash
cd backend && mvn spring-boot:run
# http://localhost:8080 | Health: /actuator/health
```

### Frontend Development (Angular)

```bash
cd frontend && npm install && ng serve
# http://localhost:4200 | Proxies /api/* to backend
```

### Full Stack via Kubernetes

```bash
./dev.sh
kubectl port-forward -n team2-demo svc/gateway-team2 3000:8080
# http://localhost:3000
```

### Monitor Running Pods

```bash
kubectl get pods -n team2-demo -w
kubectl logs -n team2-demo -f deployment/backend-team2
kubectl exec -it -n team2-demo deployment/backend-team2 -- /bin/bash
```

## Project Structure

```
team2-demo-optimized/
├── k8s/                          # Kubernetes configuration (Kustomize)
│   ├── base/                     # Shared manifests (dev + test)
│   │   ├── namespace.yaml
│   │   ├── backend-deployment.yaml
│   │   ├── gateway-deployment.yaml
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── dev/                  # Rancher Desktop (1 replica, local images)
│       │   ├── kustomization.yaml
│       │   └── README.md
│       └── test/                 # OpenShift (2 replicas, registry images)
│           ├── kustomization.yaml
│           ├── backend-patch.yaml
│           ├── gateway-patch.yaml
│           ├── route.yaml
│           ├── network-policy.yaml
│           └── README.md
├── backend/                      # Spring Boot application
│   ├── src/
│   └── pom.xml
├── frontend/                     # Angular application
│   ├── src/
│   ├── package.json
│   └── proxy.conf.json
├── gateway/                      # Nginx gateway
│   ├── nginx.conf
│   └── 50x.html
├── docker/                       # Docker build files
│   ├── Dockerfile.backend
│   └── Dockerfile.gateway
├── devbox.json                   # Development environment (Devbox)
├── dev.sh                        # Start Kubernetes development
├── build.sh                      # Build production images
└── README.md
```

## Deployment to OpenShift (Test/Production)

### 1. Build and Push Images

```bash
export REGISTRY="your-registry.io/team2"
export VERSION="0.0.1"

# Build and tag images
./build.sh

# Push to registry
docker push ${REGISTRY}/team2-backend:${VERSION}
docker push ${REGISTRY}/team2-gateway:${VERSION}
```

### 2. Deploy to OpenShift

```bash
export REGISTRY="your-registry.io/team2"
export VERSION="0.0.1"

# Deploy using test overlay
kubectl apply -k k8s/overlays/test

# Watch deployment
kubectl get pods -n team2-demo -w

# Get the route URL
kubectl get route -n team2-demo
```

### 3. Update Route Hostname

Edit `k8s/overlays/test/route.yaml` to set your cluster domain, or patch dynamically:

```bash
kubectl patch route team2-demo -n team2-demo \
  -p '{"spec":{"host":"team2-demo.apps.your-cluster.com"}}'
```

## Kubernetes Configuration

### Dev vs Test Environments

| Aspect | Dev (Rancher) | Test (OpenShift) |
|--------|---------------|-----------------|
| **Replicas** | 1 | 2 |
| **Image Pull Policy** | IfNotPresent (local) | Always (registry) |
| **Images** | `team2-backend:latest` | `${REGISTRY}/team2-backend:${VERSION}` |
| **Service Type** | NodePort:30080 | ClusterIP + Route |
| **Spring Profile** | `kubernetes` | `openshift` |
| **Network Policy** | None | Yes (ingress/egress) |

### Kustomize Overlays

The project uses **Kustomize** for managing environment-specific configurations:

- **Base** (`k8s/base/`): Common manifests shared between dev and test
- **Dev Overlay** (`k8s/overlays/dev/`): Rancher Desktop customizations
- **Test Overlay** (`k8s/overlays/test/`): OpenShift customizations

This approach avoids duplication while allowing environment-specific overrides.

## Individual Component Development

### Backend Only

```bash
cd backend
mvn spring-boot:run  # Runs on http://localhost:8080
```

### Frontend Only

```bash
cd frontend
npm install
npm start  # Runs on http://localhost:4200 with proxy to localhost:8080
```

The frontend `proxy.conf.json` automatically proxies `/api` requests to the backend during development.

## Testing

### Test Backend API

```bash
# Local (if running separately)
curl http://localhost:8080/api/hello

# Via gateway
curl http://localhost:3000/api/hello
```

Expected response:
```json
{"message":"Hello from Spring Boot Backend"}
```

### Test Health Endpoints

```bash
# Backend readiness (K8s probe)
curl http://localhost:8080/actuator/health/readiness

# Backend liveness (K8s probe)
curl http://localhost:8080/actuator/health/liveness

# Gateway health
curl http://localhost:3000/health
```

## Configuration

### Environment Variables

**Build & Deployment:**
- `REGISTRY`: Container registry URL (e.g., `quay.io/myteam`)
- `VERSION`: Image tag (e.g., `1.0.0`)

**Backend (application.yml):**
- `server.port`: HTTP port (default: 8080)
- `SPRING_PROFILES_ACTIVE`: Profile (kubernetes/openshift)

### Customize Kubernetes Resources

Edit manifests to adjust:
- **Replicas**: `k8s/overlays/dev/kustomization.yaml` or `k8s/overlays/test/kustomization.yaml`
- **Resource Limits**: `k8s/base/backend-deployment.yaml` or `k8s/base/gateway-deployment.yaml`
- **Health Check Probes**: `k8s/base/*-deployment.yaml`
- **Network Policies**: `k8s/overlays/test/network-policy.yaml`

## Production Considerations

1. **Registry**: Replace `your-registry.io/team2` with actual registry URL
2. **Route Host**: Update domain in `k8s/overlays/test/route.yaml`
3. **CORS**: Configure `@CrossOrigin` in backend for production domains
4. **Resource Limits**: Adjust based on load testing results
5. **Replicas**: Scale based on traffic in `kustomization.yaml`
6. **Monitoring**: Integrate Prometheus/Grafana for metrics
7. **Logging**: Configure centralized logging (ELK/Splunk)
8. **TLS**: Ensure Route has TLS termination enabled

## Troubleshooting

### Kubernetes Not Available
```
Error: Kubernetes cluster not available
```
**Solution**: Start Rancher Desktop and verify Kubernetes is enabled

### Pods Failing to Start
```bash
# Describe pod to see error
kubectl describe pod -n team2-demo <pod-name>

# Check logs
kubectl logs -n team2-demo <pod-name>
```

### Image Pull Errors
Ensure images are built locally before deploying to dev:
```bash
docker build -f docker/Dockerfile.backend -t team2-backend:latest .
docker build -f docker/Dockerfile.gateway -t team2-gateway:latest .
```

### Connectivity Issues
Test pod-to-pod communication:
```bash
# From gateway to backend
kubectl exec -n team2-demo deployment/gateway-team2 -- \
  wget -O- http://backend-team2:8080/api/hello
```

## Security

- **Non-root Containers**: All pods run as unprivileged users (UID 65534 for backend, 101 for gateway)
- **SecurityContext**: Enforces `runAsNonRoot: true`, drops all capabilities
- **Network Policies**: Restrict ingress/egress in production (test overlay)
- **TLS**: OpenShift Route provides edge termination
- **Headers**: Nginx adds security headers (X-Frame-Options, X-Content-Type-Options, etc.)

## Additional Resources

- **Quick Reference**: See `K8S_QUICK_REFERENCE.md` for common commands
- **AI Agent Instructions**: See `.github/copilot-instructions.md` for development patterns
- **Dev Overlay Details**: See `k8s/overlays/dev/README.md`
- **Test Overlay Details**: See `k8s/overlays/test/README.md`

## License

MIT

