# Team 2 Demo Application - Optimized

A production-ready demo application with Spring Boot backend, Angular frontend, and Nginx gateway.

## Architecture

```
┌─────────────┐
│   Gateway   │ (Nginx + Angular SPA)
│   :8080     │
└──────┬──────┘
       │
       ├─── /      → Angular Frontend (static files)
       │
       └─── /api/  → Spring Boot Backend
                     └─ /hello
                     └─ /health
```

## Key Optimizations

- **Consolidated Gateway**: Single nginx container serves frontend AND proxies backend
- **Multi-stage Builds**: Optimized Docker images with dependency caching
- **Security**: Non-root users, security contexts, network policies
- **Health Checks**: Proper liveness/readiness probes
- **Resource Management**: Sensible CPU/memory limits
- **Development Workflow**: docker-compose for local development
- **Production Ready**: Rolling updates, multiple replicas, TLS routes

## Quick Start

### Local Development

```bash
# Start all services with docker-compose
./dev.sh

# Or manually:
# Terminal 1 - Backend
cd backend
mvn spring-boot:run

# Terminal 2 - Frontend (with proxy to backend)
cd frontend
npm install
npm start
```

Access:
- Frontend: http://localhost:4200
- Backend API: http://localhost:8080/api/hello

### Build Images

```bash
export REGISTRY="your-registry.io/team2"
export VERSION="0.0.1"

./build.sh
```

### Deploy to OpenShift

```bash
# Push images first
docker push ${REGISTRY}/team2-backend:${VERSION}
docker push ${REGISTRY}/team2-gateway:${VERSION}

# Deploy
./deploy.sh

# Check deployment
kubectl get pods -n team2-demo
kubectl get route -n team2-demo
```

## Project Structure

```
team2-demo-optimized/
├── backend/              # Spring Boot application
│   ├── src/
│   └── pom.xml
├── frontend/             # Angular application
│   ├── src/
│   ├── package.json
│   └── proxy.conf.json   # Dev proxy configuration
├── gateway/              # Nginx gateway configuration
│   ├── nginx.conf
│   └── 50x.html
├── docker/               # Docker build files
│   ├── Dockerfile.backend
│   └── Dockerfile.gateway
├── openshift/            # Kubernetes/OpenShift manifests
│   ├── backend-deployment.yaml
│   ├── gateway-deployment.yaml
│   ├── route.yaml
│   ├── network-policy.yaml
│   └── kustomization.yaml
├── docker-compose.yml    # Local development
├── build.sh              # Build images
├── deploy.sh             # Deploy to OpenShift
└── dev.sh                # Start local development
```

## Configuration

### Environment Variables

**Build & Deploy:**
- `REGISTRY`: Container registry URL (default: `your-registry.io/team2`)
- `VERSION`: Image version tag (default: `0.0.1`)

**Backend (application.yml):**
- `server.port`: HTTP port (default: 8080)
- `SPRING_PROFILES_ACTIVE`: Active profile (dev/docker/openshift)

### OpenShift Route

Edit `openshift/route.yaml` to set your cluster domain:
```yaml
spec:
  host: team2-demo.apps.your-cluster.com
```

## Development

### Frontend Proxy

During development, the frontend uses a proxy configuration (`proxy.conf.json`) to forward `/api` requests to the backend running on port 8080. This avoids CORS issues.

### Hot Reload

```bash
cd frontend
npm start  # Frontend with hot reload on :4200

cd backend
mvn spring-boot:run  # Backend with devtools on :8080
```

## Testing

### Test Backend
```bash
curl http://localhost:8080/api/hello
# Expected: {"message":"Hello from Spring Boot Backend"}
```

### Test Frontend
Visit http://localhost:4200 and click "Call Backend"

### Test Gateway (Docker)
```bash
docker-compose up
curl http://localhost:3000/api/hello
```

## Production Considerations

1. **Update Registry**: Replace `your-registry.io/team2` with actual registry
2. **Update Route Host**: Set proper domain in `openshift/route.yaml`
3. **CORS Configuration**: Update `@CrossOrigin` in backend for production domains
4. **Resource Limits**: Adjust based on actual load testing
5. **Replicas**: Scale based on traffic requirements
6. **Monitoring**: Add Prometheus/Grafana for metrics
7. **Logging**: Configure centralized logging (ELK/Splunk)

## Troubleshooting

### Build Issues
```bash
# Clean Docker cache
docker system prune -a

# Rebuild without cache
docker-compose build --no-cache
```

### Deployment Issues
```bash
# Check pod logs
kubectl logs -n team2-demo deployment/backend-team2
kubectl logs -n team2-demo deployment/gateway-team2

# Check pod status
kubectl describe pod -n team2-demo <pod-name>

# Test connectivity
kubectl exec -n team2-demo deployment/gateway-team2 -- wget -O- http://backend-team2:8080/api/hello
```

### CORS Issues
If frontend can't reach backend, verify:
1. Backend CORS configuration allows the frontend origin
2. Gateway proxy_pass configuration is correct
3. Network policies allow traffic between pods

## Security

- All containers run as non-root users
- Security contexts enforce non-privileged execution
- Network policies restrict pod-to-pod communication
- TLS termination at OpenShift route
- Security headers in nginx configuration

## License

MIT
