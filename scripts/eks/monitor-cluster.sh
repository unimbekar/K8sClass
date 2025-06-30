#!/bin/bash

# =================================================================
# EKS Cluster Monitoring Script
# =================================================================
# This script provides comprehensive cluster health monitoring

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 EKS Cluster Health Monitor${NC}"
echo "=============================="

# =================================================================
# Cluster Information
# =================================================================
echo -e "${CYAN}🏢 Cluster Information${NC}"
echo "Cluster Name: $(kubectl config current-context | cut -d'/' -f2)"
echo "Kubernetes Version: $(kubectl version --short --output=json | jq -r '.serverVersion.gitVersion')"
echo "Current Context: $(kubectl config current-context)"
echo ""

# =================================================================
# Node Status
# =================================================================
echo -e "${CYAN}🖥️  Node Status${NC}"
kubectl get nodes -o custom-columns="NAME:.metadata.name,STATUS:.status.conditions[?(@.type=='Ready')].status,ROLES:.metadata.labels.kubernetes\.io/role,AGE:.metadata.creationTimestamp,VERSION:.status.nodeInfo.kubeletVersion"
echo ""

# =================================================================
# Resource Usage
# =================================================================
echo -e "${CYAN}📈 Resource Usage${NC}"
if kubectl top nodes &>/dev/null; then
    kubectl top nodes
else
    echo -e "${YELLOW}⚠️  Metrics server not available. Install with: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml${NC}"
fi
echo ""

# =================================================================
# Namespace Overview
# =================================================================
echo -e "${CYAN}📁 Namespace Overview${NC}"
kubectl get namespaces --show-labels
echo ""

# =================================================================
# System Pods Health
# =================================================================
echo -e "${CYAN}🔧 System Pods Health${NC}"
echo "kube-system namespace:"
kubectl get pods -n kube-system --field-selector=status.phase!=Running,status.phase!=Succeeded

FAILED_PODS=$(kubectl get pods -n kube-system --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | wc -l)
if [ "$FAILED_PODS" -eq 0 ]; then
    echo -e "${GREEN}✅ All system pods are healthy${NC}"
else
    echo -e "${RED}❌ $FAILED_PODS system pods are not running${NC}"
fi
echo ""

# =================================================================
# EKS Add-ons Status
# =================================================================
echo -e "${CYAN}🔌 EKS Add-ons Status${NC}"
echo "VPC CNI:"
kubectl get daemonset aws-node -n kube-system -o custom-columns="DESIRED:.status.desiredNumberScheduled,CURRENT:.status.currentNumberScheduled,READY:.status.numberReady"

echo "CoreDNS:"
kubectl get deployment coredns -n kube-system -o custom-columns="READY:.status.readyReplicas,UP-TO-DATE:.status.updatedReplicas,AVAILABLE:.status.availableReplicas"

echo "EBS CSI Controller:"
kubectl get deployment ebs-csi-controller -n kube-system -o custom-columns="READY:.status.readyReplicas,UP-TO-DATE:.status.updatedReplicas,AVAILABLE:.status.availableReplicas" 2>/dev/null || echo "EBS CSI Controller not found"
echo ""

# =================================================================
# Storage Classes
# =================================================================
echo -e "${CYAN}💾 Storage Classes${NC}"
kubectl get storageclass
echo ""

# =================================================================
# Load Balancers and Services
# =================================================================
echo -e "${CYAN}🌐 External Services${NC}"
kubectl get svc --all-namespaces --field-selector spec.type=LoadBalancer
echo ""

# =================================================================
# Ingress Controllers
# =================================================================
echo -e "${CYAN}🚪 Ingress Resources${NC}"
kubectl get ingress --all-namespaces 2>/dev/null || echo "No ingress resources found"
echo ""

# =================================================================
# Recent Events
# =================================================================
echo -e "${CYAN}📋 Recent Cluster Events (last 10)${NC}"
kubectl get events --all-namespaces --sort-by='.metadata.creationTimestamp' | tail -10
echo ""

# =================================================================
# Persistent Volumes
# =================================================================
echo -e "${CYAN}📦 Persistent Volumes${NC}"
kubectl get pv 2>/dev/null || echo "No persistent volumes found"
echo ""

echo -e "${CYAN}📦 Persistent Volume Claims${NC}"
kubectl get pvc --all-namespaces 2>/dev/null || echo "No persistent volume claims found"
echo ""

# =================================================================
# Network Policies
# =================================================================
echo -e "${CYAN}🔒 Network Policies${NC}"
kubectl get networkpolicy --all-namespaces 2>/dev/null || echo "No network policies found"
echo ""

# =================================================================
# Resource Quotas
# =================================================================
echo -e "${CYAN}📊 Resource Quotas${NC}"
kubectl get resourcequota --all-namespaces 2>/dev/null || echo "No resource quotas found"
echo ""

# =================================================================
# Certificate Status
# =================================================================
echo -e "${CYAN}🔐 Certificate Information${NC}"
echo "Cluster CA expires: $(kubectl get configmap cluster-info -n kube-public -o jsonpath='{.data.kubeconfig}' | grep certificate-authority-data | head -1)"
echo ""

# =================================================================
# Health Summary
# =================================================================
echo -e "${GREEN}📊 Health Summary${NC}"
echo "=================="

# Count healthy nodes
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)
READY_NODES=$(kubectl get nodes --no-headers | grep " Ready " | wc -l)

# Count healthy system pods
TOTAL_SYSTEM_PODS=$(kubectl get pods -n kube-system --no-headers | wc -l)
RUNNING_SYSTEM_PODS=$(kubectl get pods -n kube-system --no-headers | grep " Running " | wc -l)

echo "Nodes: $READY_NODES/$TOTAL_NODES Ready"
echo "System Pods: $RUNNING_SYSTEM_PODS/$TOTAL_SYSTEM_PODS Running"

if [ "$READY_NODES" -eq "$TOTAL_NODES" ] && [ "$RUNNING_SYSTEM_PODS" -eq "$TOTAL_SYSTEM_PODS" ]; then
    echo -e "${GREEN}✅ Cluster is healthy!${NC}"
else
    echo -e "${YELLOW}⚠️  Some components need attention${NC}"
fi

echo ""
echo -e "${BLUE}💡 Useful monitoring commands:${NC}"
echo "• Watch pods: kubectl get pods --all-namespaces -w"
echo "• Check node details: kubectl describe node <node-name>"
echo "• Monitor resources: watch kubectl top nodes"
echo "• View logs: kubectl logs -n kube-system -l k8s-app=aws-node"