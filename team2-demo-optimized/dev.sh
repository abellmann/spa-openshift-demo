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

# Check if OpenShift Local/Kubernetes is available
check_kubernetes() {
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Kubernetes cluster not available. Please start Podman Desktop with OpenShift Local extension."
        exit 1
    fi
    
    # Detect if running on CRC (OpenShift Local)
    if kubectl get nodes 2>/dev/null | grep -q "crc"; then
        print_info "OpenShift Local (CRC) detected"
        USE_CRC=true
    else
        print_info "Kubernetes cluster ready"
        USE_CRC=false
    fi
}

# Build and load images for OpenShift Local
build_images() {
    print_info "Building Docker images..."
    
    # Build with --load flag to ensure images are available
    docker build --load -f docker/Dockerfile.backend -t team2-backend:latest .
    docker build --load -f docker/Dockerfile.gateway -t team2-gateway:latest .
    
    print_info "Docker images built successfully"
    
    # If using CRC, load images into CRC's internal podman
    if [ "$USE_CRC" = true ]; then
        print_info "Loading images into OpenShift Local (CRC) internal registry..."
        
        # Save images to temporary tar files
        docker save team2-backend:latest -o /tmp/team2-backend.tar
        docker save team2-gateway:latest -o /tmp/team2-gateway.tar
        
        # Load into CRC's podman
        eval $(crc podman-env)
        podman load -i /tmp/team2-backend.tar
        podman load -i /tmp/team2-gateway.tar
        
        # Cleanup tar files
        rm -f /tmp/team2-backend.tar /tmp/team2-gateway.tar
        
        print_info "Images loaded into CRC successfully"
    fi
}

# Deploy to Kubernetes
deploy() {
    print_info "Deploying to OpenShift Local (team2-demo namespace)..."
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
    echo "Access the application via OpenShift Routes:"
    echo "  kubectl get routes -n team2-demo"
    echo ""
    echo "Routes created:"
    echo "  • team2-frontend: /app1 → gateway-team2:8080"
    echo "  • team2-backend:  /app1/api → backend-team2:8080"
    echo ""
    echo "Useful commands:"
    echo "  kubectl get pods -n team2-demo                    # Show pods"
    echo "  kubectl get routes -n team2-demo                 # Show routes"
    echo "  kubectl logs -n team2-demo -f deployment/gateway-team2  # Watch gateway logs"
    echo "  kubectl logs -n team2-demo -f deployment/backend-team2  # Watch backend logs"
    echo "  kubectl delete -k k8s/overlays/dev               # Teardown"
    echo ""
}

# Main flow
main() {
    print_info "Team 2 Demo - OpenShift Local Development Setup"
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
