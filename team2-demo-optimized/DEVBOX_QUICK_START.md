# Development Setup Summary

## Documentation
- **`DEVBOX_SETUP.md`** - Comprehensive guide and troubleshooting
- **`README.md`** - Main development workflows

## Getting Started (5 minutes)

### Prerequisites

- **Podman Desktop** with OpenShift Local extension enabled

### Setup
```bash
# Install (one-time)
curl -fsSL https://get.jetpack.io/devbox | bash

# Enter shell
devbox shell
```

### Choose Your Workflow

**Option A: Full Stack via OpenShift Local**
```bash
./dev.sh
kubectl get routes -n team2-demo
# Visit the frontend route URL (e.g., http://team2-frontend-team2-demo.apps.local/app1)
```

**Option B: Backend Only**
```bash
cd backend
mvn spring-boot:run
# Backend at http://localhost:8080
```

**Option C: Frontend Only**
```bash
cd frontend
npm install
ng serve
# Frontend at http://localhost:4200 (proxies to backend)
```

## Tools Included
**Java 17** • **Maven 3.9** • **Node.js 20** • **npm** • **Docker** • **kubectl** • **git** • **curl** • **jq** • **yq** • **make** • **vim**

## Key Commands

```bash
# Enter/exit development environment
devbox shell
exit

# Backend development
cd backend && mvn spring-boot:run

# Frontend development
cd frontend && npm install && ng serve

# Full stack deployment
./dev.sh

# Monitor Kubernetes
kubectl get pods -n team2-demo -w

# View logs
kubectl logs -n team2-demo -f deployment/backend-team2

# Access application
kubectl port-forward -n team2-demo svc/gateway-team2 3000:8080
# http://localhost:3000
```

## Benefits

- 🎯 **Consistent Environment**: Same tools and versions for all developers
- 🚀 **Easy Onboarding**: New team members run `devbox shell` - setup is instant
- 🔒 **Isolated**: No system-wide package pollution
- 📦 **Reproducible**: Matches CI/CD pipeline environments
- 🛠️ **Flexible**: Can customize via `.devbox-template.nix` if needed

## Help
- **Installation issues?** See [DEVBOX_SETUP.md](./DEVBOX_SETUP.md#troubleshooting)
- **Want to use system packages?** See [DEVBOX_SETUP.md](./DEVBOX_SETUP.md#want-to-use-system-packages-instead)
- **Development workflows?** See [README.md](./README.md)
