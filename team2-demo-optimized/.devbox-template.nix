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
    JAVA_HOME = "${pkgs.jdk17}";
    MAVEN_HOME = "${pkgs.maven}";
  };

  # System packages
  packages = with pkgs; [
    # JVM & Build Tools
    jdk17
    maven
    
    # Node.js & Frontend
    nodejs_18
    
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
    
    # Optional: for better terminal experience
    zsh
    fzf
  ];

  # Shell initialization
  shell = {
    init_hook = ''
      echo "🚀 Team 2 Demo Development Environment"
      echo "📦 Installed tools:"
      java -version 2>&1 | head -1
      mvn --version 2>&1 | head -1
      node --version
      npm --version
      docker --version
      kubectl version --client 2>/dev/null || echo "kubectl not configured"
      git --version
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
