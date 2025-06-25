# Amazon EKS Cluster Deployment

This Terraform configuration creates a production-ready Amazon EKS (Elastic Kubernetes Service) cluster with security best practices, essential add-ons, and proper networking configuration. The cluster is designed to work with the VPC infrastructure using CIDR `172.25.0.0/16`.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            EKS Cluster Architecture                              │
│                               172.25.0.0/16                                     │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                                 Control Plane                                   │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                            EKS Managed                                  │   │
│  │   • API Server          • etcd             • Controller Manager        │   │
│  │   • Scheduler           • Cloud Controller • Add-on Manager           │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                     │                                           │
│                            ┌────────┴────────┐                                 │
│                            │ OIDC Provider   │                                 │
│                            │ (IRSA Support)  │                                 │
│                            └─────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
                                       │
                              ┌────────┴────────┐
                              │  Load Balancer  │
                              │  (Public Subnet)│
                              └────────┬────────┘
                                       │
┌─────────────────────────────────────────────────────────────────────────────────┐
│                               Data Plane (Workers)                              │
│                                                                                 │
│  AZ-A                      AZ-B                      AZ-C                      │
│  ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐       │
│  │ Private Subnet  │       │ Private Subnet  │       │ Private Subnet  │       │
│  │ 172.25.1.0/24   │       │ 172.25.2.0/24   │       │ 172.25.3.0/24   │       │
│  │                 │       │                 │       │                 │       │
│  │ ┌─────────────┐ │       │ ┌─────────────┐ │       │ ┌─────────────┐ │       │
│  │ │Worker Node 1│ │       │ │Worker Node 2│ │       │ │Worker Node 3│ │       │
│  │ │  t3.medium  │ │       │ │  t3.medium  │ │       │ │  t3.medium  │ │       │
│  │ └─────────────┘ │       │ └─────────────┘ │       │ └─────────────┘ │       │
│  │                 │       │                 │       │                 │       │
│  │ ┌─────────────┐ │       │ ┌─────────────┐ │       │ ┌─────────────┐ │       │
│  │ │   Pod 1     │ │       │ │   Pod 2     │ │       │ │   Pod 3     │ │       │
│  │ │   Pod 2     │ │       │ │   Pod 3     │ │       │ │   Pod 4     │ │       │
│  │ └─────────────┘ │       │ └─────────────┘ │       │ └─────────────┘ │       │
│  └─────────────────┘       └─────────────────┘       └─────────────────┘       │
│           │                         │                         │               │
│           └─────────────────────────┼─────────────────────────┘               │
│                                     │                                         │
│                        ┌────────────┴────────────┐                            │
│                        │      NAT Gateway        │                            │
│                        │   (Public Subnet)       │                            │
│                        └─────────────────────────┘                            │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Essential Add-ons                                  │
│                                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │  VPC CNI    │  │  CoreDNS    │  │ EBS CSI     │  │ OIDC        │            │
│  │ (Networking)│  │    (DNS)    │  │ (Storage)   │  │ Provider    │            │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🎯 What This Configuration Creates

### Core EKS Components
- **EKS Cluster**: Kubernetes 1.28 control plane managed by AWS
- **Managed Node Group**: Auto-scaling worker nodes in private subnets
- **Security Groups**: Cluster and node security groups with proper rules
- **IAM Roles**: Service accounts with OIDC provider for pod-level permissions

### Essential Add-ons
- **VPC CNI**: Advanced networking with prefix delegation
- **CoreDNS**: Cluster DNS resolution service
- **EBS CSI Driver**: Persistent volume support for stateful applications

### Security Features
- **Private Worker Nodes**: Nodes deployed in private subnets
- **KMS Encryption**: Secrets encryption at rest
- **Security Groups**: Fine-grained network access control
- **OIDC Provider**: IAM roles for service accounts (IRSA)

### Monitoring & Logging
- **CloudWatch Logs**: Comprehensive cluster logging
- **Audit Logging**: API server audit trails
- **Control Plane Logs**: Full visibility into cluster operations

## 📋 Prerequisites

### Infrastructure Dependencies
1. **VPC Infrastructure**: Must be deployed first using the VPC configuration
2. **IAM Roles**: EKS service roles from the IAM configuration
3. **S3 Backend**: Terraform state bucket configured

### Required Tools
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.28
- [eksctl](https://eksctl.io/) (optional, for additional cluster management)

### Required Permissions
Your AWS credentials need:
- Full EKS permissions (`eks:*`)
- EC2 permissions for security groups and launch templates
- IAM permissions for service roles and OIDC provider
- CloudWatch and KMS permissions for logging and encryption

## 🚀 Step-by-Step Deployment

### Step 1: Prepare Your Environment

```bash
# Create EKS cluster directory
mkdir eks-cluster && cd eks-cluster

# Copy all the configuration files to this directory:
# - main.tf
# - variables.tf  
# - outputs.tf
# - versions.tf
# - terraform.tfvars.example
# - templates/userdata.sh (create templates directory first)

# Create the templates directory
mkdir templates
```

### Step 2: Configure Variables

```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit the configuration (customize as needed)
vim terraform.tfvars
```

**Key variables to customize:**
```hcl
# Essential settings
cluster_name = "k8sclass-cluster"
aws_region = "us-east-1"
state_bucket = "k8sclass-tf-state-0625"

# Security settings
cluster_endpoint_public_access_cidrs = ["YOUR_IP/32"]  # Restrict access

# Node configuration
node_group_instance_types = ["t3.medium"]
node_group_desired_size = 2
```

### Step 3: Initialize Terraform

```bash
# Initialize Terraform
terraform init

# Expected output:
# Initializing the backend...
# Initializing provider plugins...
# Terraform has been successfully initialized!
```

### Step 4: Validate Configuration

```bash
# Validate the configuration
terraform validate

# Check formatting
terraform fmt

# Plan the deployment
terraform plan
```

**Review the plan carefully. You should see:**
- 1 EKS cluster
- 1 EKS node group
- 2 security groups
- 3 EKS add-ons
- 1 OIDC provider
- 2 KMS keys
- 1 CloudWatch log group
- Various IAM roles and policies

### Step 5: Deploy the Cluster

```bash
# Deploy the EKS cluster (takes 10-15 minutes)
terraform apply

# Type 'yes' when prompted
# ✅ Cluster creation typically takes 10-15 minutes
# ✅ Node group creation takes an additional 5-10 minutes
```

### Step 6: Configure kubectl

```bash
# Update kubeconfig to connect to your cluster
aws eks update-kubeconfig --region us-east-1 --name k8sclass-cluster

# Verify connection
kubectl get nodes

# Expected output:
# NAME                                        STATUS   ROLES    AGE   VERSION
# ip-172-25-1-xxx.us-east-1.compute.internal   Ready    <none>   5m    v1.28.x
# ip-172-25-2-xxx.us-east-1.compute.internal   Ready    <none>   5m    v1.28.x
```

### Step 7: Verify Cluster Health

```bash
# Check cluster info
kubectl cluster-info

# Check all nodes
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check add-ons
kubectl get pods -n kube-system | grep -E "(coredns|aws-node|ebs-csi)"
```

## 🔍 Configuration Details

### Network Architecture

**Subnet Placement:**
- **Control Plane**: Managed by AWS across multiple AZs
- **Worker Nodes**: Private subnets (172.25.1.0/24, 172.25.2.0/24, 172.25.3.0/24)
- **Load Balancers**: Public subnets (172.25.101.0/24, 172.25.102.0/24, 172.25.103.0/24)

**Security Groups:**
```hcl
# Cluster Security Group
- Ingress: HTTPS (443) from VPC CIDR (172.25.0.0/16)
- Egress: All traffic outbound

# Node Security Group  
- Ingress: Node-to-node communication (all ports)
- Ingress: Cluster-to-node communication (1025-65535)
- Ingress: HTTPS from cluster (443)
- Egress: All traffic outbound
```

### Instance Configuration

**Default Worker Node Specs:**
- **Instance Type**: t3.medium (2 vCPU, 4 GiB RAM)
- **AMI**: Amazon Linux 2 EKS-optimized
- **Root Volume**: 20 GiB GP3, encrypted
- **Container Runtime**: containerd
- **Auto Scaling**: 1-6 nodes, desired 2

### Add-on Versions
- **VPC CNI**: v1.15.1 (latest stable)
- **CoreDNS**: v1.10.1 (DNS resolution)
- **EBS CSI**: v1.24.0 (persistent volumes)

## 🧪 Testing Your Cluster

### Step 1: Deploy a Test Application

```bash
# Create a test namespace
kubectl create namespace test-app

# Deploy a simple nginx application
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  namespace: test-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: test-app
spec:
  selector:
    app: nginx-test
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF
```

### Step 2: Verify Application Deployment

```bash
# Check pod status
kubectl get pods -n test-app

# Check service and get load balancer URL
kubectl get svc -n test-app

# Wait for load balancer to be ready (takes 2-3 minutes)
kubectl get svc nginx-service -n test-app -w
```

### Step 3: Test Application Access

```bash
# Get the load balancer URL
LOAD_BALANCER=$(kubectl get svc nginx-service -n test-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test the application
curl http://$LOAD_BALANCER

# Expected output: nginx welcome page HTML
```

### Step 4: Test Persistent Volumes

```bash
# Create a persistent volume claim
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: test-app
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp2
  resources:
    requests:
      storage: 1Gi
EOF

# Check PVC status
kubectl get pvc -n test-app

# Expected status: Bound
```

## 🔧 Customization Options

### Development Environment

```hcl
# terraform.tfvars for development
node_group_instance_types = ["t3.small"]
node_group_desired_size = 1
node_group_max_size = 3
node_group_capacity_type = "SPOT"  # Cost savings
cloudwatch_log_retention_days = 3
```

### Production Environment

```hcl
# terraform.tfvars for production
node_group_instance_types = ["m5.large"]
node_group_desired_size = 3
node_group_max_size = 10
node_group_capacity_type = "ON_DEMAND"
cluster_endpoint_public_access = false  # Private only
cloudwatch_log_retention_days = 30
kms_key_deletion_window = 30

# Add multiple node groups for different workloads
```

### High-Performance Computing

```hcl
# For CPU-intensive workloads
node_group_instance_types = ["c5.2xlarge"]
node_group_disk_size = 50

# For GPU workloads
node_group_instance_types = ["g4dn.xlarge"]
node_group_ami_type = "AL2_x86_64_GPU"
```

## 📊 Monitoring and Logging

### CloudWatch Integration

**Cluster Logs Available:**
- API server logs
- Audit logs
- Authenticator logs
- Controller manager logs
- Scheduler logs

**Accessing Logs:**
```bash
# View cluster logs in CloudWatch
aws logs describe-log-groups --log-group-name-prefix /aws/eks/k8sclass-cluster

# Stream real-time logs
aws logs tail /aws/eks/k8sclass-cluster/cluster --follow
```

### Prometheus and Grafana (Optional)

```bash
# Install kube-prometheus-stack using Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install with custom values for EKS
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.service.type=LoadBalancer
```

## 🔐 Security Best Practices

### Network Security
- ✅ Worker nodes in private subnets
- ✅ Security groups with minimal required access
- ✅ VPC CNI with security group for pods capability
- ✅ Private API endpoint option available

### Identity and Access Management
- ✅ OIDC provider for service account roles
- ✅ Pod-level IAM permissions via IRSA
- ✅ Service roles with least privilege
- ✅ Audit logging enabled

### Data Protection
- ✅ Secrets encryption with customer-managed KMS keys
- ✅ EBS volumes encrypted at rest
- ✅ CloudWatch logs encrypted
- ✅ TLS encryption for all communications

### Runtime Security
```bash
# Example: Deploy Falco for runtime security monitoring
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco \
  --namespace falco-system \
  --create-namespace
```

## 💰 Cost Optimization

### Current Cost Estimate (us-east-1)

**Monthly Costs:**
- **EKS Control Plane**: $73/month
- **Worker Nodes** (2x t3.medium): ~$60/month
- **NAT Gateway**: ~$45/month
- **EBS Volumes** (2x 20GB): ~$4/month
- **Load Balancer**: ~$18/month
- **Data Transfer**: Variable

**Total Estimated**: ~$200/month

### Cost Reduction Strategies

1. **Use Spot Instances:**
   ```hcl
   node_group_capacity_type = "SPOT"
   # Can save 60-70% on compute costs
   ```

2. **Right-size Instances:**
   ```hcl
   node_group_instance_types = ["t3.small"]  # For light workloads
   ```

3. **Optimize Storage:**
   ```hcl
   node_group_disk_size = 20  # Minimum recommended
   ```

4. **Use Fargate for Specific Workloads:**
   ```hcl
   # Add Fargate profiles for serverless pods
   # No worker node costs for Fargate pods
   ```

## 🔄 Cluster Management

### Upgrading Kubernetes Version

```bash
# 1. Upgrade control plane
terraform apply -var="kubernetes_version=1.29"

# 2. Upgrade node groups (done automatically with managed node groups)
# 3. Update add-ons if needed
```

### Scaling Worker Nodes

```bash
# Scale via Terraform
terraform apply -var="node_group_desired_size=4"

# Or scale via kubectl
kubectl scale --replicas=4 deployment/cluster-autoscaler -n kube-system
```

### Adding Node Groups

```hcl
# Add to main.tf for specialized workloads
resource "aws_eks_node_group" "gpu_nodes" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.cluster_name}-gpu-nodes"
  node_role_arn   = local.node_group_role_arn
  subnet_ids      = local.private_subnet_ids
  
  instance_types = ["g4dn.xlarge"]
  ami_type      = "AL2_x86_64_GPU"
  
  scaling_config {
    desired_size = 0
    max_size     = 5
    min_size     = 0
  }
  
  # GPU-specific taints
  taint {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }
}
```

## 🛟 Troubleshooting

### Common Issues

#### Issue 1: Nodes Not Joining Cluster
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name k8sclass-cluster --nodegroup-name main-nodes

# Check CloudWatch logs for node group
aws logs tail /aws/eks/k8sclass-cluster/cluster --follow | grep -i error

# SSH to node (if debugging access enabled)
# Check kubelet logs: journalctl -u kubelet -f
```

#### Issue 2: Pods Stuck in Pending
```bash
# Check node resources
kubectl describe nodes

# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Common causes:
# - Insufficient CPU/memory resources
# - Node selector constraints
# - Taints and tolerations mismatch
```

#### Issue 3: Load Balancer Not Creating
```bash
# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer

# Check service annotations
kubectl describe service <service-name> -n <namespace>

# Install AWS Load Balancer Controller if missing
```

#### Issue 4: DNS Resolution Issues
```bash
# Check CoreDNS pods
kubectl get pods -n kube-system | grep coredns

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

### Debug Commands

```bash
# Cluster information
kubectl cluster-info dump

# Node status details
kubectl get nodes -o yaml

# Check all system pods
kubectl get pods -A

# EKS cluster status
aws eks describe-cluster --name k8sclass-cluster

# Recent cluster events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 🧹 Cleanup

### Destroy Test Resources

```bash
# Delete test application
kubectl delete namespace test-app

# This also deletes the load balancer and PVC
```

### Destroy EKS Cluster

```bash
# ⚠️ WARNING: This will destroy the entire cluster and all data

# 1. Delete any load balancers first (to avoid stuck resources)
kubectl get svc --all-namespaces -o wide | grep LoadBalancer

# 2. Delete the cluster infrastructure
terraform destroy

# Type 'yes' when prompted
# Deletion takes 10-15 minutes
```

## 📚 Next Steps

After deploying your EKS cluster:

1. **Install Essential Tools:**
   - AWS Load Balancer Controller
   - Cluster Autoscaler
   - External DNS
   - Cert Manager

2. **Set Up CI/CD:**
   - GitHub Actions or GitLab CI
   - ArgoCD for GitOps
   - Helm for package management

3. **Implement Monitoring:**
   - Prometheus and Grafana
   - AWS CloudWatch Container Insights
   - Jaeger for distributed tracing

4. **Security Hardening:**
   - Pod Security Standards
   - Network Policies
   - Falco for runtime security

## 📖 Additional Resources

- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [EKS Workshop](https://www.eksworkshop.com/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

**🎉 Congratulations!** You now have a production-ready EKS cluster running on your custom VPC with proper security, monitoring, and scalability features. The cluster is ready for deploying containerized applications and learning Kubernetes concepts.