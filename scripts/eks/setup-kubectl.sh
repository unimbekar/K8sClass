#!/bin/bash

# =================================================================
# EKS Cluster Setup Script
# =================================================================
# This script configures kubectl and tests your EKS cluster
# Run this after your EKS cluster is deployed

set -e

echo "🚀 Setting up EKS cluster access..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =================================================================
# Step 1: Configure kubectl
# =================================================================
echo -e "${BLUE}📋 Step 1: Configuring kubectl...${NC}"
aws eks update-kubeconfig --region us-east-1 --name k8sclass-cluster

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ kubectl configured successfully!${NC}"
else
    echo -e "${RED}❌ Failed to configure kubectl${NC}"
    exit 1
fi

# =================================================================
# Step 2: Test cluster connection
# =================================================================
echo -e "${BLUE}📋 Step 2: Testing cluster connection...${NC}"
kubectl cluster-info

# =================================================================
# Step 3: Check nodes
# =================================================================
echo -e "${BLUE}📋 Step 3: Checking cluster nodes...${NC}"
kubectl get nodes -o wide

# Wait for nodes to be ready
echo -e "${YELLOW}⏳ Waiting for nodes to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=300s

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ All nodes are ready!${NC}"
else
    echo -e "${YELLOW}⚠️  Some nodes might still be initializing${NC}"
fi

# =================================================================
# Step 4: Check system pods
# =================================================================
echo -e "${BLUE}📋 Step 4: Checking system pods...${NC}"
kubectl get pods -n kube-system

# =================================================================
# Step 5: Check add-ons
# =================================================================
echo -e "${BLUE}📋 Step 5: Checking EKS add-ons...${NC}"
echo "VPC CNI:"
kubectl get pods -n kube-system -l k8s-app=aws-node

echo "CoreDNS:"
kubectl get pods -n kube-system -l k8s-app=kube-dns

echo "EBS CSI Driver:"
kubectl get pods -n kube-system -l app=ebs-csi-controller

# =================================================================
# Step 6: Create test namespace
# =================================================================
echo -e "${BLUE}📋 Step 6: Creating test namespace...${NC}"
kubectl create namespace test-apps --dry-run=client -o yaml | kubectl apply -f -

# =================================================================
# Summary
# =================================================================
echo -e "${GREEN}"
echo "🎉 EKS Cluster Setup Complete!"
echo "================================"
echo "Cluster Name: k8sclass-cluster"
echo "Region: us-east-1"
echo "Kubernetes Version: $(kubectl version --short --client | grep Client | awk '{print $3}')"
echo "Nodes: $(kubectl get nodes --no-headers | wc -l)"
echo -e "${NC}"

echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run './test-cluster.sh' to deploy test applications"
echo "2. Run './monitor-cluster.sh' to check cluster health"
echo "3. Check README-kubectl-commands.md for more commands"