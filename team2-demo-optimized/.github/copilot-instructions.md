# Copilot Instructions for Team 2 Demo Application

## Architecture Overview

This is a production-grade SPA with three key components:

**Unified Gateway Pattern**: A single Nginx container (port 8080) serves the Angular SPA AND proxies API calls to the backend. The gateway is the only exposed service in Kubernetes.

- **Gateway** (`gateway/nginx.conf`): Routes `/` to Angular static files, `/api/*` to backend via Docker DNS (`backend-team2:8080`)
- **Backend** (Spring Boot 3.2, Java 17): RESTful API with health endpoints at `/actuator/health`
- **Frontend** (Angular): SPA served by Nginx with asset caching (1-year expires for js/css/images)

Data flow: Browser → Nginx:8080 → (static files OR proxied to Java:8080)

## Build & Deploy Workflow

**Local Development** (`./dev.sh`):
- Starts docker-compose which builds both backend and gateway, connects via `team2-network` bridge
- Backend health check: `curl http://localhost:8080/actuator/health`
- Gateway health check: `curl http://localhost:3000/health`
- Frontend runs at `http://localhost:3000`

**Production Build** (`./build.sh`):
- Sets `REGISTRY` and `VERSION` env vars
- Multi-stage builds minimize images: Maven layers cached by `dependency:go-offline`
- Produces tagged images: `${REGISTRY}/team2-backend:${VERSION}` and `${REGISTRY}/team2-gateway:${VERSION}`

**Kubernetes Deployment** (`./deploy.sh`):
- Creates `team2-demo` namespace
- Backend: 2 replicas with rolling updates (maxSurge=1, maxUnavailable=0)
- Health checks use `/actuator/health/readiness` and `/actuator/health/liveness`
- Non-root users enforced in SecurityContext (pod-level and container-level)

## Key Files & Patterns

| File | Purpose | Key Pattern |
|------|---------|------------|
| `gateway/nginx.conf` | Routing, security headers, proxy config | `try_files $uri $uri/ /index.html` for SPA fallback |
| `backend/pom.xml` | Maven config, Spring Boot 3.2 parent | Java 17 target, Spring Actuator enabled |
| `frontend/proxy.conf.json` | Dev-only proxy to backend | Points to `http://localhost:8080` for npm start |
| `openshift/*-deployment.yaml` | K8s manifests | Replicas, resource requests, rolling strategy |
| `docker/Dockerfile.*` | Multi-stage builds | Separate build/runtime stages, non-root USER |

## Critical Conventions

1. **Backend health endpoints**: Always use `/actuator/health/readiness` (K8s probes) and `/actuator/health/liveness` (Docker healthchecks use `/actuator/health`)
2. **CORS in backend**: `@CrossOrigin(origins = "*")` on controllers—note comment to restrict in production
3. **Environment profiles**: Backend respects `SPRING_PROFILES_ACTIVE` (docker/openshift in containers, defaults to dev locally)
4. **Docker DNS**: Internal container communication uses service names: `backend-team2:8080` (defined in docker-compose and K8s Service)
5. **Non-root execution**: All containers run as non-root user; Nginx runs as `nginx`, Java as `spring`

## Development Commands

```bash
# Start local stack
./dev.sh

# Backend only (from backend/ dir)
mvn spring-boot:run

# Frontend dev server (from frontend/ dir, proxies via proxy.conf.json)
npm start

# Build images locally
./build.sh

# Push to registry & deploy to cluster
docker push ${REGISTRY}/team2-backend:${VERSION}
docker push ${REGISTRY}/team2-gateway:${VERSION}
./deploy.sh
```

## Common Modification Points

- **Add backend endpoint**: Create method in `HelloController.java`, add route to `nginx.conf` if new path
- **Change frontend build**: Modify `frontend/angular.json` (output path must match Dockerfile.gateway COPY target `/build/dist/team2-frontend/`)
- **Adjust resource limits**: Edit `resources.requests|limits` in `openshift/*-deployment.yaml`
- **Update Nginx behavior**: Edit `gateway/nginx.conf`, rebuild with `./build.sh`

## Dependencies & Versions

- Java 17 (eclipse-temurin base images in Dockerfiles)
- Spring Boot 3.2.0 (parent in pom.xml)
- Angular 18+ (check `frontend/package.json`)
- Nginx 1.25 Alpine (gateway Dockerfile)
- Node 18 Alpine (frontend build stage)

## Known Constraints & Decisions

1. **Consolidated gateway**: No separate ingress controller—all traffic flows through one Nginx pod
2. **CORS permissive**: `origins = "*"` is intentional for demo; tighten for production
3. **K8s service name**: Backend K8s Service MUST be named `backend-team2` (hard-coded in `nginx.conf` as `http://backend-team2:8080/api/`)
4. **Rolling updates**: Gateway depends on backend health; ensure readiness probes are accurate before making rapid deployments

