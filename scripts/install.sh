#!/bin/bash

# =================================================================
# EKS Tools Installation Script
# =================================================================
# This script installs all necessary tools for EKS cluster management
# Supports: Linux (Ubuntu/Debian/RHEL/CentOS/Amazon Linux) and macOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =================================================================
# Functions
# =================================================================
print_header() {
    echo -e "${BLUE}"
    echo "=============================================="
    echo "$1"
    echo "=============================================="
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            VER=$VERSION_ID
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
    else
        OS="Unknown"
    fi
    echo "Detected OS: $OS"
}

# =================================================================
# Main Installation
# =================================================================
print_header "🚀 EKS Tools Installation Script"

echo -e "${BLUE}This script will install:${NC}"
echo "• AWS CLI v2"
echo "• kubectl"
echo "• eksctl"
echo "• Helm"
echo "• jq (JSON processor)"
echo "• curl (if not present)"
echo "• Optional: Docker, k9s, kubectx/kubens"
echo ""

# Detect operating system
detect_os

# Check for sudo access
if ! sudo -n true 2>/dev/null; then
    print_warning "This script requires sudo access. You may be prompted for your password."
fi

# =================================================================
# Install prerequisites
# =================================================================
print_header "📦 Installing Prerequisites"

if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
    print_info "Installing prerequisites for Ubuntu/Debian..."
    sudo apt-get update
    sudo apt-get install -y curl wget unzip git jq
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Amazon Linux"* ]]; then
    print_info "Installing prerequisites for RHEL/CentOS/Amazon Linux..."
    sudo yum update -y
    sudo yum install -y curl wget unzip git jq || sudo dnf install -y curl wget unzip git jq
elif [[ "$OS" == "macOS" ]]; then
    print_info "Installing prerequisites for macOS..."
    if ! command_exists brew; then
        print_warning "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install curl wget jq git
else
    print_warning "Unknown OS. Please install curl, wget, unzip, git, and jq manually."
fi

print_success "Prerequisites installed"

# =================================================================
# Install AWS CLI v2
# =================================================================
print_header "☁️ Installing AWS CLI v2"

if command_exists aws; then
    AWS_VERSION=$(aws --version 2>&1 | head -n1 | awk '{print $1}' | cut -d'/' -f2)
    print_info "AWS CLI $AWS_VERSION is already installed"
    
    # Check if it's v2
    if [[ $AWS_VERSION == 2.* ]]; then
        print_success "AWS CLI v2 is already installed"
    else
        print_warning "AWS CLI v1 detected. Upgrading to v2..."
        INSTALL_AWS_CLI=true
    fi
else
    INSTALL_AWS_CLI=true
fi

if [[ "$INSTALL_AWS_CLI" == "true" ]]; then
    if [[ "$OS" == "macOS" ]]; then
        print_info "Installing AWS CLI v2 for macOS..."
        curl -fsSL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
        sudo installer -pkg AWSCLIV2.pkg -target /
        rm AWSCLIV2.pkg
    else
        print_info "Installing AWS CLI v2 for Linux..."
        curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip -q awscliv2.zip
        sudo ./aws/install --update
        rm -rf aws awscliv2.zip
    fi
    print_success "AWS CLI v2 installed"
fi

# Verify AWS CLI installation
aws --version

# =================================================================
# Install kubectl
# =================================================================
print_header "⚙️ Installing kubectl"

if command_exists kubectl; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | awk '{print $3}' || echo "unknown")
    print_info "kubectl $KUBECTL_VERSION is already installed"
    
    read -p "$(echo -e ${YELLOW}"Do you want to update kubectl to the latest version? (y/N): "${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_KUBECTL=true
    fi
else
    INSTALL_KUBECTL=true
fi

if [[ "$INSTALL_KUBECTL" == "true" ]]; then
    # Get latest stable version
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    print_info "Installing kubectl $KUBECTL_VERSION..."
    
    if [[ "$OS" == "macOS" ]]; then
        curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/darwin/amd64/kubectl"
    else
        curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
    fi
    
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    print_success "kubectl installed"
fi

# Verify kubectl installation
kubectl version --client --short

# =================================================================
# Install eksctl
# =================================================================
print_header "🔧 Installing eksctl"

if command_exists eksctl; then
    EKSCTL_VERSION=$(eksctl version 2>/dev/null || echo "unknown")
    print_info "eksctl $EKSCTL_VERSION is already installed"
    
    read -p "$(echo -e ${YELLOW}"Do you want to update eksctl to the latest version? (y/N): "${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_EKSCTL=true
    fi
else
    INSTALL_EKSCTL=true
fi

if [[ "$INSTALL_EKSCTL" == "true" ]]; then
    print_info "Installing eksctl..."
    
    if [[ "$OS" == "macOS" ]]; then
        PLATFORM="darwin_amd64"
    else
        PLATFORM="linux_amd64"
    fi
    
    # Get latest release URL
    EKSCTL_URL=$(curl -s https://api.github.com/repos/weaveworks/eksctl/releases/latest | jq -r ".assets[] | select(.name | test(\"eksctl_${PLATFORM}\")) | .browser_download_url")
    
    curl -sL "$EKSCTL_URL" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
    print_success "eksctl installed"
fi

# Verify eksctl installation
eksctl version

# =================================================================
# Install Helm
# =================================================================
print_header "⎈ Installing Helm"

if command_exists helm; then
    HELM_VERSION=$(helm version --short 2>/dev/null | cut -d'+' -f1 || echo "unknown")
    print_info "Helm $HELM_VERSION is already installed"
    
    read -p "$(echo -e ${YELLOW}"Do you want to update Helm to the latest version? (y/N): "${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_HELM=true
    fi
else
    INSTALL_HELM=true
fi

if [[ "$INSTALL_HELM" == "true" ]]; then
    print_info "Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    print_success "Helm installed"
fi

# Verify Helm installation
helm version --short

# =================================================================
# Optional Tools Installation
# =================================================================
print_header "🛠️ Optional Tools"

# Docker
read -p "$(echo -e ${YELLOW}"Do you want to install Docker? (y/N): "${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ "$OS" == "macOS" ]]; then
        print_info "Please install Docker Desktop for Mac from: https://docs.docker.com/desktop/install/mac-install/"
    elif [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        print_info "Installing Docker for Ubuntu/Debian..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        print_warning "Please log out and back in for Docker group changes to take effect"
    else
        print_info "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
    fi
    print_success "Docker installation completed"
fi

# k9s (Kubernetes CLI UI)
read -p "$(echo -e ${YELLOW}"Do you want to install k9s (Kubernetes CLI UI)? (y/N): "${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installing k9s..."
    if [[ "$OS" == "macOS" ]]; then
        brew install k9s
    else
        # Get latest k9s release
        K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)
        if [[ "$OS" == *"ARM"* ]] || [[ "$(uname -m)" == "aarch64" ]]; then
            ARCH="arm64"
        else
            ARCH="amd64"
        fi
        
        wget -q "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${ARCH}.tar.gz" -O k9s.tar.gz
        tar -xzf k9s.tar.gz
        sudo mv k9s /usr/local/bin/
        rm k9s.tar.gz LICENSE README.md
    fi
    print_success "k9s installed"
fi

# kubectx and kubens
read -p "$(echo -e ${YELLOW}"Do you want to install kubectx and kubens (context and namespace switchers)? (y/N): "${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installing kubectx and kubens..."
    if [[ "$OS" == "macOS" ]]; then
        brew install kubectx
    else
        sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
        sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
        sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
    fi
    print_success "kubectx and kubens installed"
fi

# kustomize
read -p "$(echo -e ${YELLOW}"Do you want to install kustomize? (y/N): "${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installing kustomize..."
    if [[ "$OS" == "macOS" ]]; then
        brew install kustomize
    else
        curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
        sudo mv kustomize /usr/local/bin/
    fi
    print_success "kustomize installed"
fi

# =================================================================
# Configure kubectl bash completion and aliases
# =================================================================
print_header "⚡ Setting up kubectl enhancements"

read -p "$(echo -e ${YELLOW}"Do you want to set up kubectl bash completion and useful aliases? (y/N): "${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Setting up kubectl enhancements..."
    
    # Determine shell config file
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.bashrc"
    fi
    
    # Backup existing config
    cp "$SHELL_RC" "$SHELL_RC.backup-$(date +%Y%m%d-%H%M%S)"
    
    # Add kubectl completion and aliases
    cat >> "$SHELL_RC" << 'EOF'

# ============================================
# Kubernetes/EKS Configuration (Added by install.sh)
# ============================================

# kubectl completion
if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion bash)
    # Enable completion for alias 'k'
    complete -F __start_kubectl k
fi

# eksctl completion
if command -v eksctl >/dev/null 2>&1; then
    source <(eksctl completion bash)
fi

# helm completion
if command -v helm >/dev/null 2>&1; then
    source <(helm completion bash)
fi

# Useful kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kdp='kubectl describe pod'
alias kds='kubectl describe svc'
alias kdd='kubectl describe deployment'
alias kdn='kubectl describe node'
alias kl='kubectl logs'
alias kle='kubectl logs -f'
alias ke='kubectl exec -it'
alias kpf='kubectl port-forward'
alias kgns='kubectl get namespaces'
alias kcn='kubectl config set-context --current --namespace'
alias kcc='kubectl config current-context'
alias kgc='kubectl config get-contexts'

# eksctl aliases
alias e='eksctl'
alias egl='eksctl get cluster'
alias egn='eksctl get nodegroup'

# Useful functions
kexec() {
    kubectl exec -it "$1" -- /bin/bash 2>/dev/null || kubectl exec -it "$1" -- /bin/sh
}

klogs() {
    kubectl logs -f "$1"
}

kport() {
    kubectl port-forward "$1" "$2" "$3"
}

# Set namespace for current context
kns() {
    if [ -z "$1" ]; then
        kubectl config view --minify --output 'jsonpath={..namespace}'
        echo
    else
        kubectl config set-context --current --namespace="$1"
        echo "Namespace switched to: $1"
    fi
}

# Get all resources in current namespace
kall() {
    kubectl get all,pvc,secrets,configmaps,ingress
}

EOF

    print_success "kubectl enhancements added to $SHELL_RC"
    print_info "Run 'source $SHELL_RC' or restart your terminal to apply changes"
fi

# =================================================================
# Configure AWS CLI (if not already configured)
# =================================================================
print_header "🔐 AWS CLI Configuration"

if [ ! -f "$HOME/.aws/credentials" ] && [ ! -f "$HOME/.aws/config" ]; then
    read -p "$(echo -e ${YELLOW}"AWS CLI is not configured. Do you want to configure it now? (y/N): "${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Starting AWS CLI configuration..."
        print_info "You'll need your AWS Access Key ID and Secret Access Key"
        aws configure
        print_success "AWS CLI configured"
    else
        print_warning "AWS CLI not configured. You can configure it later with 'aws configure'"
        print_info "Or use AWS SSO with 'aws configure sso'"
    fi
else
    print_success "AWS CLI is already configured"
fi

# =================================================================
# Final verification and summary
# =================================================================
print_header "✅ Installation Summary"

echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
echo ""
echo -e "${BLUE}Installed tools:${NC}"

# Check each tool
tools=("aws" "kubectl" "eksctl" "helm" "jq")
for tool in "${tools[@]}"; do
    if command_exists "$tool"; then
        version=$($tool version --short 2>/dev/null || $tool --version 2>/dev/null | head -1 || echo "installed")
        echo -e "${GREEN}✅ $tool${NC} - $version"
    else
        echo -e "${RED}❌ $tool${NC} - not found"
    fi
done

# Check optional tools
optional_tools=("docker" "k9s" "kubectx" "kubens" "kustomize")
echo ""
echo -e "${BLUE}Optional tools:${NC}"
for tool in "${optional_tools[@]}"; do
    if command_exists "$tool"; then
        version=$($tool --version 2>/dev/null | head -1 || echo "installed")
        echo -e "${GREEN}✅ $tool${NC} - $version"
    else
        echo -e "${YELLOW}⏸️  $tool${NC} - not installed"
    fi
done

echo ""
echo -e "${CYAN}📋 Next Steps:${NC}"
echo "1. Source your shell configuration: source ~/.bashrc (or ~/.zshrc)"
echo "2. Configure your EKS cluster access:"
echo "   aws eks update-kubeconfig --region us-east-1 --name k8sclass-cluster"
echo "3. Test your setup:"
echo "   kubectl get nodes"
echo "4. Run the setup script: ./setup-kubectl.sh"
echo ""

echo -e "${BLUE}📚 Useful commands to get started:${NC}"
echo "• k get nodes               # List cluster nodes (k is alias for kubectl)"
echo "• k get pods -A             # List all pods in all namespaces"
echo "• k9s                       # Start k9s UI (if installed)"
echo "• kubectx                   # Switch between clusters (if installed)"
echo "• kubens                    # Switch between namespaces (if installed)"
echo ""

echo -e "${YELLOW}💡 Pro Tips:${NC}"
echo "• Use 'k' instead of 'kubectl' (faster typing)"
echo "• Use tab completion for commands and resource names"
echo "• Use 'kns <namespace>' to switch namespaces quickly"
echo "• Use 'kall' to see all resources in current namespace"

print_success "All tools are ready for EKS cluster management!"