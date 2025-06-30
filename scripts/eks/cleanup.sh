#!/bin/bash

# =================================================================
# EKS Cluster Cleanup Script
# =================================================================
# This script helps clean up test resources and prepare for cluster deletion

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 EKS Cluster Cleanup Script${NC}"
echo "=============================="

# =================================================================
# Function: Confirm action
# =================================================================
confirm() {
    read -p "$(echo -e ${YELLOW}$1${NC}) (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# =================================================================
# 1. Clean up test applications
# =================================================================
if confirm "🗑️  Delete test-apps namespace and all test resources?"; then
    echo -e "${BLUE}Cleaning up test applications...${NC}"
    kubectl delete namespace test-apps --ignore-not-found=true
    echo -e "${GREEN}✅ Test applications cleaned up${NC}"
fi

# =================================================================
# 2. Clean up LoadBalancers
# =================================================================
echo -e "${BLUE}🔍 Checking for LoadBalancer services...${NC}"
LB_SERVICES=$(kubectl get svc --all-namespaces --field-selector spec.type=LoadBalancer --no-headers 2>/dev/null | wc -l)

if [ "$LB_SERVICES" -gt 0 ]; then
    echo -e "${YELLOW}Found $LB_SERVICES LoadBalancer service(s):${NC}"
    kubectl get svc --all-namespaces --field-selector spec.type=LoadBalancer
    
    if confirm "Delete all LoadBalancer services?"; then
        kubectl get svc --all-namespaces --field-selector spec.type=LoadBalancer -o json | \
        jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' | \
        while read namespace name; do
            echo "Deleting LoadBalancer: $namespace/$name"
            kubectl delete svc "$name" -n "$namespace"
        done
        echo -e "${GREEN}✅ LoadBalancer services deleted${NC}"
    fi
else
    echo -e "${GREEN}✅ No LoadBalancer services found${NC}"
fi

# =================================================================
# 3. Clean up Persistent Volumes
# =================================================================
echo -e "${BLUE}🔍 Checking for Persistent Volume Claims...${NC}"
PVC_COUNT=$(kubectl get pvc --all-namespaces --no-headers 2>/dev/null | wc -l)

if [ "$PVC_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}Found $PVC_COUNT PVC(s):${NC}"
    kubectl get pvc --all-namespaces
    
    if confirm "Delete all Persistent Volume Claims?"; then
        kubectl get pvc --all-namespaces -o json | \
        jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' | \
        while read namespace name; do
            echo "Deleting PVC: $namespace/$name"
            kubectl delete pvc "$name" -n "$namespace"
        done
        echo -e "${GREEN}✅ PVCs deleted${NC}"
    fi
else
    echo -e "${GREEN}✅ No PVCs found${NC}"
fi

# =================================================================
# 4. Clean up failed/completed pods
# =================================================================
if confirm "🧽 Clean up failed and completed pods?"; then
    echo -e "${BLUE}Cleaning up failed pods...${NC}"
    kubectl get pods --all-namespaces --field-selector=status.phase=Failed -o json | kubectl delete -f - 2>/dev/null || true
    
    echo -e "${BLUE}Cleaning up completed jobs...${NC}"
    kubectl delete jobs --all-namespaces --field-selector=status.successful=1 2>/dev/null || true
    
    echo -e "${GREEN}✅ Failed and completed resources cleaned up${NC}"
fi

# =================================================================
# 5. Clean up custom namespaces
# =================================================================
echo -e "${BLUE}🔍 Checking for custom namespaces...${NC}"
CUSTOM_NS=$(kubectl get namespaces --no-headers | grep -v -E "(default|kube-system|kube-public|kube-node-lease)" | awk '{print $1}')

if [ ! -z "$CUSTOM_NS" ]; then
    echo -e "${YELLOW}Found custom namespaces:${NC}"
    echo "$CUSTOM_NS"
    
    if confirm "Delete all custom namespaces? (This will delete all resources in them)"; then
        echo "$CUSTOM_NS" | while read ns; do
            echo "Deleting namespace: $ns"
            kubectl delete namespace "$ns" --wait=false
        done
        echo -e "${GREEN}✅ Custom namespaces deletion initiated${NC}"
    fi
else
    echo -e "${GREEN}✅ No custom namespaces found${NC}"
fi

# =================================================================
# 6. Check for remaining resources
# =================================================================
echo -e "${BLUE}📊 Checking remaining resources...${NC}"

# Check for remaining LoadBalancers
REMAINING_LB=$(kubectl get svc --all-namespaces --field-selector spec.type=LoadBalancer --no-headers 2>/dev/null | wc -l)
if [ "$REMAINING_LB" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $REMAINING_LB LoadBalancer(s) still exist${NC}"
fi

# Check for remaining PVCs
REMAINING_PVC=$(kubectl get pvc --all-namespaces --no-headers 2>/dev/null | wc -l)
if [ "$REMAINING_PVC" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $REMAINING_PVC PVC(s) still exist${NC}"
fi

# =================================================================
# 7. AWS Resource Check
# =================================================================
echo -e "${BLUE}☁️  Checking AWS resources...${NC}"

# Check for ELBs created by services
echo "Checking for ELBs created by Kubernetes services..."
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s`) || contains(Tags[?Key==`kubernetes.io/cluster/k8sclass-cluster`].Value, `owned`)].LoadBalancerName' --output table 2>/dev/null || echo "No ELBs found or AWS CLI error"

# Check for EBS volumes
echo "Checking for EBS volumes created by PVCs..."
aws ec2 describe-volumes --filters Name=tag:kubernetes.io/cluster/k8sclass-cluster,Values=owned --query 'Volumes[].VolumeId' --output table 2>/dev/null || echo "No EBS volumes found or AWS CLI error"

# =================================================================
# 8. Cleanup confirmation
# =================================================================
echo -e "${GREEN}"
echo "🎉 Cleanup Summary"
echo "=================="
echo -e "${NC}"

if [ "$REMAINING_LB" -eq 0 ] && [ "$REMAINING_PVC" -eq 0 ]; then
    echo -e "${GREEN}✅ Cluster is clean and ready for deletion${NC}"
    echo ""
    echo -e "${BLUE}To delete the entire EKS cluster, run:${NC}"
    echo "cd /path/to/your/eks/terraform"
    echo "terraform destroy"
    echo ""
    echo -e "${BLUE}Or using eksctl:${NC}"
    echo "eksctl delete cluster --name k8sclass-cluster --region us-east-1"
else
    echo -e "${YELLOW}⚠️  Some resources still exist. Please review and clean up manually if needed.${NC}"
    echo ""
    echo -e "${BLUE}Check remaining resources:${NC}"
    echo "kubectl get svc --all-namespaces --field-selector spec.type=LoadBalancer"
    echo "kubectl get pvc --all-namespaces"
fi

echo ""
echo -e "${BLUE}💡 Additional cleanup commands:${NC}"
echo "• Force delete stuck namespace: kubectl delete namespace <ns> --force --grace-period=0"
echo "• Delete all resources in namespace: kubectl delete all --all -n <namespace>"
echo "• Check for finalizers: kubectl get <resource> <name> -o yaml | grep finalizers"

echo ""
echo -e "${YELLOW}⚠️  Note: Always ensure LoadBalancers and PVCs are deleted before destroying the cluster${NC}"
echo -e "${YELLOW}   to avoid orphaned AWS resources that may incur charges.${NC}"