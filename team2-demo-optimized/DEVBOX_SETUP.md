# Devbox Setup Guide

This project includes a `devbox.json` configuration to provide a consistent, reproducible development environment for all team members.

## What is Devbox?

[Devbox](https://www.jetpack.io/devbox) is a lightweight development environment manager that uses [Nix](https://nixos.org) under the hood. It ensures everyone on the team has the same tools and versions, eliminating "works on my machine" issues.

## Installation

### One-Time Setup

```bash
# Install Devbox (requires curl)
curl -fsSL https://get.jetpack.io/devbox | bash

# Verify installation
devbox --version
```

### Alternative: Using Homebrew (macOS)

```bash
brew install jetpack-io/devbox/devbox
```

## Quick Start

### Enter Development Environment

```bash
# Navigate to project root
cd /path/to/team2-demo-optimized

# Enter Devbox shell with all pre-configured tools
devbox shell

# You're now in an isolated shell with all dependencies ready!
```

### Exit Development Environment

```bash
# Simply exit the shell
exit

# Or use Ctrl+D
```

## What Tools Are Included?

Java 17 • Maven 3.9 • Node.js 20 • npm • Docker • kubectl • git • curl • jq • yq • make • vim

## Development Workflows

### Full Stack Development (OpenShift Local)

```bash
# Install Podman Desktop with OpenShift Local extension first
# Then start the environment:
devbox shell
./dev.sh

# Get route URLs
kubectl get routes -n team2-demo
```

### Backend Development

```bash
devbox shell
cd backend
mvn spring-boot:run
# Runs on http://localhost:8080
```

### Frontend Development

```bash
devbox shell
cd frontend
npm install
ng serve
# Runs on http://localhost:4200 (proxies /api to backend)
```

All development work should happen inside `devbox shell` to ensure consistent tool versions.

## System Requirements

### For OpenShift Local Development

- **Podman Desktop** - Container platform
- **OpenShift Local extension** - Local OpenShift cluster
- **At least 10GB RAM** - For running OpenShift Local
- **macOS, Linux, or Windows** - Supported by Podman Desktop

See [Podman Desktop documentation](https://podman-desktop.io/) for installation instructions.

## Advanced Configuration

### Using a Custom Nix File

If you need more advanced configuration (environment variables, custom packages, etc.):

1. Copy `.devbox-template.nix` to `devbox.nix`:
   ```bash
   cp .devbox-template.nix devbox.nix
   ```

2. Delete or rename `devbox.json`:
   ```bash
   mv devbox.json devbox.json.bak
   ```

3. Edit `devbox.nix` as needed and enter the shell:
   ```bash
   devbox shell
   ```

### Adding More Packages

To add additional tools to your development environment:

**With `devbox.json`:**
Edit the `packages` array and re-enter the shell:
```json
"packages": [
  "java17",
  "maven",
  ...
  "your-new-package"
]
```

**With `devbox.nix`:**
Edit the `packages` list and re-enter the shell:
```nix
packages = with pkgs; [
  your-new-package
  ...
];
```

## Troubleshooting

### "Nix is not installed"

If you see this error, install Nix first:
```bash
# macOS / Linux
curl -L https://nixos.org/nix/install | sh

# Or with Homebrew (macOS)
brew install nix
```

### "devbox command not found" after installation

Restart your terminal or run:
```bash
source ~/.bashrc  # for bash
source ~/.zshrc   # for zsh
```

### Slow First Start

The first time you run `devbox shell`, it may download and build packages. This is normal and usually takes a few minutes. Subsequent shells start much faster.

### Tools Not Available

If tools aren't available in the devbox shell, try:

1. Exit the shell: `exit`
2. Clear cache: `devbox cache clean`
3. Re-enter: `devbox shell`

### Want to Use System Packages Instead?

You can skip Devbox and install tools manually:

**macOS (with Homebrew):**
```bash
brew install openjdk@17 maven node docker
brew tap homebrew/cask
brew install kubectl docker
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install openjdk-17-jdk maven nodejs npm docker.io
# See: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
```

However, we recommend using Devbox to ensure consistency across the team.

## Benefits

✅ Identical tool versions across team • ✅ Reproducible builds • ✅ Easy onboarding • ✅ No system pollution • ✅ Matches CI/CD

## Additional Resources

- [Devbox Documentation](https://www.jetpack.io/devbox/docs)
- [Nixpkgs Search](https://search.nixos.org/packages) - Find available packages
- [Nix Manual](https://nixos.org/manual/nix/stable/)

## Questions?

Refer to the main [README.md](./README.md) for project-specific information.
