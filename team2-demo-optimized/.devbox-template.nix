# Advanced Devbox configuration template (optional)
# This file provides an alternative way to define your development environment
# with more fine-grained control than devbox.json
#
# To use this instead of devbox.json, rename this file to devbox.nix and
# delete or rename devbox.json. Then run: devbox shell

{ pkgs, ... }:

{
  # Environment variables
  env = {
    JAVA_HOME = "${pkgs.openjdk17}";
  };

  # System packages
  packages = with pkgs; [
    # JVM & Build Tools
    openjdk17
    maven_3_9
    
    # Node.js & Frontend
    nodejs_20
    
    # Container & Orchestration
    docker
    kubectl
    
    # Utilities
    git
    curl
    jq
    yq
    gnumake
    vim
  ];

  # Shell initialization
  shell = {
    init_hook = ''
      echo "🚀 Team 2 Demo Development Environment"
      echo "📦 Installed tools:"
      java -version 2>&1 | head -1
      mvn --version 2>&1 | head -1
      echo "Node.js: $(node --version)"
      echo "npm: $(npm --version)"
      docker --version
      echo "kubectl: $(kubectl version --client 2>&1 | head -1)"
      git --version
      curl --version 2>&1 | head -1
      jq --version
      yq --version
      make --version 2>&1 | head -1
      vim --version 2>&1 | head -1
      echo ""
      echo "📚 Quick Start:"
      echo "  ./dev.sh              - Deploy to local Kubernetes (Rancher Desktop)"
      echo "  kubectl port-forward -n team2-demo svc/gateway-team2 3000:8080"
      echo "  open http://localhost:3000"
      echo ""
      echo "🔨 Development:"
      echo "  Backend: cd backend && mvn spring-boot:run"
      echo "  Frontend: cd frontend && npm install && ng serve"
      echo ""
    '';
  };
}
