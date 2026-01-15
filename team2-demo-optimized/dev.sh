#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Rancher Desktop K8s is available
check_kubernetes() {
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Kubernetes cluster not available. Please start Rancher Desktop and enable Kubernetes."
        exit 1
    fi
    print_info "Kubernetes cluster is ready"
}

# Build Docker images locally
build_images() {
    print_info "Building Docker images..."
    
    docker build -f docker/Dockerfile.backend -t team2-backend:latest . &
    docker build -f docker/Dockerfile.gateway -t team2-gateway:latest . &
    
    wait
    print_info "Docker images built successfully"
}

# Deploy to Kubernetes
deploy() {
    print_info "Deploying to Rancher Desktop (team2-demo namespace)..."
    kubectl apply -k k8s/overlays/dev
    print_info "Deployment created"
}

# Wait for pods to be ready
wait_for_pods() {
    print_info "Waiting for pods to be ready (this may take a minute)..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=team2-demo -n team2-demo --timeout=300s || true
    
    print_info "Checking pod status..."
    kubectl get pods -n team2-demo
}

# Show access information
show_access_info() {
    print_info "Application deployed successfully!"
    echo ""
    echo "Access the application:"
    echo "  kubectl port-forward -n team2-demo svc/gateway-team2 3000:8080"
    echo ""
    echo "Then visit: http://localhost:3000"
    echo ""
    echo "Useful commands:"
    echo "  kubectl get pods -n team2-demo                    # Show pods"
    echo "  kubectl logs -n team2-demo -f deployment/gateway-team2  # Watch gateway logs"
    echo "  kubectl logs -n team2-demo -f deployment/backend-team2  # Watch backend logs"
    echo "  kubectl delete -k k8s/overlays/dev               # Teardown"
    echo ""
}

# Main flow
main() {
    print_info "Team 2 Demo - Kubernetes Development Setup (Rancher Desktop)"
    echo ""
    
    check_kubernetes
    echo ""
    
    build_images
    echo ""
    
    deploy
    echo ""
    
    wait_for_pods
    echo ""
    
    show_access_info
}

main
