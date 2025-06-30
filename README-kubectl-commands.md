# EKS Cluster kubectl Commands Reference

This comprehensive guide covers essential kubectl and eksctl commands for managing your EKS cluster.

## 🛠️ Prerequisites and Installation

### Quick Setup
```bash
# Run the installation script to install all required tools
chmod +x install.sh
./install.sh

# Or install manually (see sections below)
```

### Required Tools

#### 1. AWS CLI v2
```bash
# macOS
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version

# Configure AWS CLI
aws configure
# OR for SSO
aws configure sso
```

#### 2. kubectl
```bash
# Get latest version
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

# macOS
curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/darwin/amd64/kubectl"

# Linux
curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"

# Make executable and move to PATH
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify installation
kubectl version --client
```

#### 3. eksctl
```bash
# macOS
PLATFORM=darwin_amd64

# Linux
PLATFORM=linux_amd64

# Download and install
EKSCTL_URL=$(curl -s https://api.github.com/repos/weaveworks/eksctl/releases/latest | jq -r ".assets[] | select(.name | test(\"eksctl_${PLATFORM}\")) | .browser_download_url")
curl -sL "$EKSCTL_URL" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Verify installation
eksctl version
```

#### 4. Helm (Package Manager for Kubernetes)
```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version
```

#### 5. Additional Useful Tools
```bash
# jq (JSON processor)
# Ubuntu/Debian: sudo apt-get install jq
# RHEL/CentOS: sudo yum install jq
# macOS: brew install jq

# k9s (Kubernetes CLI UI)
# macOS: brew install k9s
# Linux: Download from https://github.com/derailed/k9s/releases

# kubectx/kubens (context and namespace switcher)
# macOS: brew install kubectx
# Linux: git clone https://github.com/ahmetb/kubectx /opt/kubectx
#        sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
#        sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
```

### Shell Configuration (Optional but Recommended)

Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
# kubectl completion
source <(kubectl completion bash)
complete -F __start_kubectl k  # Enable completion for alias 'k'

# eksctl completion
source <(eksctl completion bash)

# helm completion
source <(helm completion bash)

# Useful aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kds='kubectl describe svc'
alias kl='kubectl logs'
alias ke='kubectl exec -it'

# Functions
kexec() { kubectl exec -it "$1" -- /bin/bash 2>/dev/null || kubectl exec -it "$1" -- /bin/sh; }
klogs() { kubectl logs -f "$1"; }
kns() { kubectl config set-context --current --namespace="$1"; }
```

## 🚀 Quick Start

```bash
# Set up kubectl access to your cluster
aws eks update-kubeconfig --region us-east-1 --name k8sclass-cluster

# Verify connection
kubectl cluster-info
kubectl get nodes

# Test with our convenience scripts
./setup-kubectl.sh
./test-cluster.sh
```

## 📋 Table of Contents

1. [Cluster Information](#cluster-information)
2. [Node Management](#node-management)
3. [Pod Operations](#pod-operations)
4. [Service Management](#service-management)
5. [Deployment Operations](#deployment-operations)
6. [Storage Management](#storage-management)
7. [Networking](#networking)
8. [Troubleshooting](#troubleshooting)
9. [eksctl Commands](#eksctl-commands)
10. [Advanced Operations](#advanced-operations)

## 🏢 Cluster Information

### Basic Cluster Info
```bash
# Get cluster information
kubectl cluster-info

# Get cluster version
kubectl version --short

# View current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>

# View cluster configuration
kubectl config view

# Get API resources
kubectl api-resources
```

### Cluster Details
```bash
# Get cluster details with eksctl
eksctl get cluster --name k8sclass-cluster --region us-east-1

# Get cluster information from AWS CLI
aws eks describe-cluster --name k8sclass-cluster --region us-east-1

# Check EKS add-ons
aws eks list-addons --cluster-name k8sclass-cluster --region us-east-1
```

## 🖥️ Node Management

### Node Information
```bash
# List all nodes
kubectl get nodes

# Detailed node information
kubectl get nodes -o wide

# Describe specific node
kubectl describe node <node-name>

# Get node labels
kubectl get nodes --show-labels

# Filter nodes by label
kubectl get nodes -l kubernetes.io/instance-type=t3.medium
```

### Node Operations
```bash
# Cordon a node (mark as unschedulable)
kubectl cordon <node-name>

# Uncordon a node
kubectl uncordon <node-name>

# Drain a node (evict all pods)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Taint a node
kubectl taint nodes <node-name> key=value:NoSchedule

# Remove taint
kubectl taint nodes <node-name> key=value:NoSchedule-
```

### Node Resource Usage
```bash
# Install metrics server first
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# View node resource usage
kubectl top nodes

# Sort by CPU usage
kubectl top nodes --sort-by=cpu

# Sort by memory usage
kubectl top nodes --sort-by=memory
```

## 🔷 Pod Operations

### Basic Pod Commands
```bash
# List all pods in current namespace
kubectl get pods

# List pods in all namespaces
kubectl get pods --all-namespaces

# List pods in specific namespace
kubectl get pods -n <namespace>

# Get detailed pod information
kubectl get pods -o wide

# Describe a pod
kubectl describe pod <pod-name>
```

### Pod Lifecycle
```bash
# Create a test pod
kubectl run test-pod --image=nginx:latest

# Create pod from YAML
kubectl apply -f pod.yaml

# Delete a pod
kubectl delete pod <pod-name>

# Force delete a pod
kubectl delete pod <pod-name> --force --grace-period=0

# Watch pod status changes
kubectl get pods -w
```

### Pod Logs and Debugging
```bash
# View pod logs
kubectl logs <pod-name>

# Follow logs in real-time
kubectl logs -f <pod-name>

# View logs from previous container instance
kubectl logs <pod-name> --previous

# View logs from specific container in multi-container pod
kubectl logs <pod-name> -c <container-name>

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/bash

# Execute command in specific container
kubectl exec -it <pod-name> -c <container-name> -- /bin/bash

# Copy files to/from pod
kubectl cp <local-file> <pod-name>:<path>
kubectl cp <pod-name>:<path> <local-file>
```

### Pod Troubleshooting
```bash
# Get pod events
kubectl describe pod <pod-name> | grep Events -A 10

# Check pod resource usage
kubectl top pod <pod-name>

# Port forward to pod
kubectl port-forward pod/<pod-name> 8080:80

# Debug with temporary pod
kubectl run debug-pod --image=busybox:1.35 --rm -it -- sh
```

## 🌐 Service Management

### Service Operations
```bash
# List all services
kubectl get services
kubectl get svc

# List services in all namespaces
kubectl get svc --all-namespaces

# Describe a service
kubectl describe svc <service-name>

# Create a service
kubectl expose deployment <deployment-name> --port=80 --target-port=8080 --type=ClusterIP

# Create LoadBalancer service
kubectl expose deployment <deployment-name> --port=80 --type=LoadBalancer
```

### Service Types Examples
```bash
# ClusterIP (internal only)
kubectl create service clusterip my-service --tcp=80:8080

# NodePort (accessible from nodes)
kubectl create service nodeport my-service --tcp=80:8080

# LoadBalancer (external access)
kubectl create service loadbalancer my-service --tcp=80:8080

# Check service endpoints
kubectl get endpoints <service-name>
```

### Service Testing
```bash
# Port forward to service
kubectl port-forward svc/<service-name> 8080:80

# Test service connectivity from pod
kubectl run test-pod --image=busybox:1.35 --rm -it -- sh
# Inside the pod:
wget -qO- <service-name>.<namespace>.svc.cluster.local
```

## 🚀 Deployment Operations

### Deployment Management
```bash
# Create deployment
kubectl create deployment nginx-deployment --image=nginx:1.21

# Create deployment with replicas
kubectl create deployment nginx-deployment --image=nginx:1.21 --replicas=3

# Get deployments
kubectl get deployments
kubectl get deploy

# Describe deployment
kubectl describe deployment <deployment-name>

# Delete deployment
kubectl delete deployment <deployment-name>
```

### Scaling Operations
```bash
# Scale deployment
kubectl scale deployment <deployment-name> --replicas=5

# Autoscale deployment
kubectl autoscale deployment <deployment-name> --min=2 --max=10 --cpu-percent=80

# Check horizontal pod autoscaler
kubectl get hpa
```

### Rolling Updates
```bash
# Update deployment image
kubectl set image deployment/<deployment-name> <container-name>=<new-image>

# Check rollout status
kubectl rollout status deployment/<deployment-name>

# View rollout history
kubectl rollout history deployment/<deployment-name>

# Rollback to previous version
kubectl rollout undo deployment/<deployment-name>

# Rollback to specific revision
kubectl rollout undo deployment/<deployment-name> --to-revision=2

# Pause rollout
kubectl rollout pause deployment/<deployment-name>

# Resume rollout
kubectl rollout resume deployment/<deployment-name>
```

## 💾 Storage Management

### Persistent Volumes
```bash
# List persistent volumes
kubectl get pv

# List persistent volume claims
kubectl get pvc

# Describe PVC
kubectl describe pvc <pvc-name>

# Create PVC from YAML
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp2
  resources:
    requests:
      storage: 10Gi
EOF
```

### Storage Classes
```bash
# List storage classes
kubectl get storageclass
kubectl get sc

# Describe storage class
kubectl describe sc gp2

# Set default storage class
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### Volume Operations
```bash
# Check volume mounts in pod
kubectl describe pod <pod-name> | grep -A 5 Mounts

# Create pod with volume
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-volume
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-pvc
EOF
```

## 🔗 Networking

### Network Information
```bash
# List network policies
kubectl get networkpolicy

# List ingress resources
kubectl get ingress

# Check service endpoints
kubectl get endpoints

# View cluster DNS configuration
kubectl get configmap coredns -n kube-system -o yaml
```

### DNS Testing
```bash
# Test DNS resolution
kubectl run dns-test --image=busybox:1.35 --rm -it -- sh
# Inside the pod:
nslookup kubernetes.default.svc.cluster.local
nslookup <service-name>.<namespace>.svc.cluster.local
```

### Load Balancer Operations
```bash
# Create LoadBalancer service
kubectl expose deployment <deployment-name> --type=LoadBalancer --port=80

# Get LoadBalancer external IP
kubectl get svc <service-name> -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Watch for LoadBalancer provisioning
kubectl get svc <service-name> -w
```

## 🔧 Troubleshooting

### General Debugging
```bash
# Get all resources in namespace
kubectl get all -n <namespace>

# Check cluster events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check recent events
kubectl get events --field-selector involvedObject.kind=Pod

# View node conditions
kubectl describe nodes | grep -A 5 Conditions

# Check resource usage
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### Common Issues
```bash
# Pods stuck in Pending
kubectl describe pod <pod-name> | grep -A 10 Events
kubectl get nodes -o wide
kubectl describe nodes

# Pods stuck in CrashLoopBackOff
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name>

# Service not accessible
kubectl get endpoints <service-name>
kubectl describe svc <service-name>

# DNS issues
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# Image pull issues
kubectl describe pod <pod-name> | grep "Failed to pull image"
kubectl get nodes -o wide

# Check kubelet logs on node
aws ssm start-session --target <instance-id>
sudo journalctl -u kubelet -f
```

### Performance Debugging
```bash
# Check resource quotas
kubectl get resourcequota --all-namespaces

# Check limit ranges
kubectl get limitrange --all-namespaces

# Monitor resource usage
watch kubectl top nodes
watch kubectl top pods --all-namespaces

# Check for resource pressure
kubectl describe nodes | grep -A 5 "Conditions"
```

## 🛠️ eksctl Commands

### Cluster Management
```bash
# List clusters
eksctl get cluster

# Get cluster details
eksctl get cluster --name k8sclass-cluster --region us-east-1

# Update cluster
eksctl update cluster --name k8sclass-cluster --region us-east-1

# Delete cluster (⚠️ Be careful!)
eksctl delete cluster --name k8sclass-cluster --region us-east-1
```

### Node Group Management
```bash
# List node groups
eksctl get nodegroup --cluster k8sclass-cluster --region us-east-1

# Scale node group
eksctl scale nodegroup --cluster k8sclass-cluster --name k8sclass-cluster-main-nodes --nodes 3 --region us-east-1

# Create additional node group
eksctl create nodegroup \
  --cluster k8sclass-cluster \
  --name workers-spot \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 4 \
  --spot \
  --region us-east-1

# Delete node group
eksctl delete nodegroup --cluster k8sclass-cluster --name <nodegroup-name> --region us-east-1
```

### Add-on Management
```bash
# List add-ons
eksctl get addon --cluster k8sclass-cluster --region us-east-1

# Install AWS Load Balancer Controller
eksctl create iamserviceaccount \
  --cluster k8sclass-cluster \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --override-existing-serviceaccounts \
  --region us-east-1 \
  --approve

# Install EBS CSI driver service account
eksctl create iamserviceaccount \
  --cluster k8sclass-cluster \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --override-existing-serviceaccounts \
  --region us-east-1 \
  --approve
```

### IAM Service Accounts (IRSA)
```bash
# Create IAM service account
eksctl create iamserviceaccount \
  --cluster k8sclass-cluster \
  --name my-service-account \
  --namespace default \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  --region us-east-1 \
  --approve

# List IAM service accounts
eksctl get iamserviceaccount --cluster k8sclass-cluster --region us-east-1

# Delete IAM service account
eksctl delete iamserviceaccount --cluster k8sclass-cluster --name my-service-account --namespace default --region us-east-1
```

## 🔬 Advanced Operations

### Custom Resources
```bash
# Get custom resource definitions
kubectl get crd

# List custom resources
kubectl get <crd-name>

# Describe custom resource
kubectl describe <crd-name> <resource-name>
```

### RBAC Management
```bash
# Check current permissions
kubectl auth can-i get pods
kubectl auth can-i create deployments --namespace kube-system

# Check permissions for service account
kubectl auth can-i get pods --as=system:serviceaccount:default:my-sa

# List roles and role bindings
kubectl get roles,rolebindings --all-namespaces
kubectl get clusterroles,clusterrolebindings

# Create role and role binding
kubectl create role pod-reader --verb=get --verb=list --verb=watch --resource=pods
kubectl create rolebinding pod-reader-binding --role=pod-reader --user=jane
```

### Labels and Annotations
```bash
# Add labels to resources
kubectl label pods <pod-name> environment=production

# Remove labels
kubectl label pods <pod-name> environment-

# Select resources by labels
kubectl get pods -l environment=production
kubectl get pods -l 'environment in (production,staging)'

# Add annotations
kubectl annotate pod <pod-name> description="My important pod"

# Remove annotations
kubectl annotate pod <pod-name> description-
```

### Patch Operations
```bash
# Strategic merge patch
kubectl patch deployment nginx-deployment -p '{"spec":{"replicas":3}}'

# JSON patch
kubectl patch pod <pod-name> --type='json' -p='[{"op": "replace", "path": "/spec/containers/0/image", "value":"nginx:1.22"}]'

# Merge patch
kubectl patch configmap <configmap-name> --type merge -p '{"data":{"key":"new-value"}}'
```

## 📊 Monitoring and Observability

### Metrics Server
```bash
# Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check metrics server
kubectl get deployment metrics-server -n kube-system

# Use metrics
kubectl top nodes
kubectl top pods --all-namespaces
```

### Prometheus and Grafana (Optional)
```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.service.type=LoadBalancer

# Access Grafana
kubectl get svc -n monitoring monitoring-grafana
# Default credentials: admin/prom-operator
```

## 🧹 Cleanup and Maintenance

### Resource Cleanup
```bash
# Delete all resources in namespace
kubectl delete all --all -n <namespace>

# Delete namespace (and all resources in it)
kubectl delete namespace <namespace>

# Delete resources by label
kubectl delete pods -l app=nginx

# Delete completed jobs
kubectl delete jobs --field-selector=status.successful=1

# Delete evicted pods
kubectl get pods --all-namespaces --field-selector=status.phase=Failed -o json | kubectl delete -f -
```

### Backup Operations
```bash
# Backup all resources in namespace
kubectl get all -o yaml -n <namespace> > backup.yaml

# Backup specific resource types
kubectl get configmaps,secrets -o yaml -n <namespace> > config-backup.yaml

# Backup cluster-wide resources
kubectl get clusterroles,clusterrolebindings -o yaml > cluster-backup.yaml
```

## 🔧 Useful Aliases and Functions

Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
# kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kds='kubectl describe svc'
alias kdd='kubectl describe deployment'
alias kl='kubectl logs'
alias ke='kubectl exec -it'

# eksctl aliases
alias e='eksctl'
alias egl='eksctl get cluster'
alias egn='eksctl get nodegroup'

# Functions
kexec() {
    kubectl exec -it "$1" -- /bin/bash
}

klogs() {
    kubectl logs -f "$1"
}

kport() {
    kubectl port-forward "$1" "$2"
}
```

## 🚨 Emergency Procedures

### Cluster Recovery
```bash
# Check cluster health
kubectl get componentstatuses

# Restart core components (if using self-managed)
kubectl delete pods -n kube-system -l component=kube-apiserver
kubectl delete pods -n kube-system -l component=kube-controller-manager
kubectl delete pods -n kube-system -l component=kube-scheduler

# For EKS, check control plane logs in CloudWatch
aws logs describe-log-groups --log-group-name-prefix /aws/eks/k8sclass-cluster
```

### Node Recovery
```bash
# Restart kubelet on node (via SSM)
aws ssm start-session --target <instance-id>
sudo systemctl restart kubelet

# Check node logs
sudo journalctl -u kubelet -f

# Replace problematic node
eksctl delete nodegroup --cluster k8sclass-cluster --name <nodegroup-name>
eksctl create nodegroup --cluster k8sclass-cluster --name <new-nodegroup-name>
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [eksctl Documentation](https://eksctl.io/usage/creating-and-managing-clusters/)

## 🎯 Quick Test Commands

```bash
# Test complete cluster functionality
kubectl run test-pod --image=nginx:latest --rm -it -- curl -I localhost
kubectl run busybox --image=busybox:1.35 --rm -it -- nslookup kubernetes.default
kubectl create deployment test-deploy --image=nginx:latest && kubectl expose deployment test-deploy --port=80 --type=LoadBalancer
```

---

**💡 Pro Tips:**
- Use `kubectl explain <resource>` to get resource documentation
- Use `kubectl diff -f <file>` to preview changes before applying
- Use `kubectl get events --sort-by=.metadata.creationTimestamp` for chronological events
- Use `kubectl config set-context --current --namespace=<namespace>` to set default namespace
- Use `kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found` to list all resources in current namespace