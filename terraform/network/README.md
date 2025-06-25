# EKS-Ready VPC Infrastructure

This Terraform configuration creates a production-ready VPC (Virtual Private Cloud) specifically designed for Amazon EKS (Elastic Kubernetes Service) clusters. The infrastructure follows AWS best practices and includes all necessary components for a secure, scalable Kubernetes environment.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    VPC: 172.25.0.0/16 (65,536 IPs)               │
├─────────────────────────────────────────────────────────────────┤
│  Availability Zone A   │  Availability Zone B   │  AZ C         │
├─────────────────────────────────────────────────────────────────┤
│ Public Subnet          │ Public Subnet          │ Public Subnet │
│ 172.25.101.0/24         │ 172.25.102.0/24         │ 172.25.103.0/24│
│ (Internet Gateway)     │                        │               │
│ ┌─────────────────┐   │                        │               │
│ │   NAT Gateway   │   │                        │               │
│ └─────────────────┘   │                        │               │
├─────────────────────────────────────────────────────────────────┤
│ Private Subnet         │ Private Subnet         │ Private Subnet│
│ 172.25.1.0/24           │ 172.25.2.0/24           │ 172.25.3.0/24  │
│ (EKS Worker Nodes)     │ (EKS Worker Nodes)     │ (EKS Nodes)   │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 What This Configuration Creates

### Core VPC Components
- **VPC**: Main virtual private cloud with CIDR `172.25.0.0/16`
- **Internet Gateway**: Enables internet access for public subnets
- **3 Public Subnets**: One per AZ for load balancers and NAT gateways
- **3 Private Subnets**: One per AZ for EKS worker nodes and applications
- **NAT Gateway**: Enables outbound internet access for private resources
- **Route Tables**: Proper routing for public and private traffic

### EKS-Specific Features
- **Proper Subnet Tagging**: Required tags for EKS service discovery
- **Multi-AZ Design**: High availability across 3 availability zones
- **Private Worker Placement**: Secure placement of Kubernetes nodes
- **Load Balancer Support**: Tagged subnets for both internal and external LBs

## 🔧 Key Features

### 🔒 Security
- **Private subnets** for worker nodes (no direct internet access)
- **NAT Gateway** for secure outbound internet connectivity
- **Proper network segmentation** between public and private resources

### 🏋️ High Availability
- **Multi-AZ deployment** across 3 availability zones
- **Redundant subnet design** for fault tolerance
- **Load balancer distribution** across multiple zones

### 📊 Scalability
- **Large IP address space** (65,536 total IPs)
- **Room for growth** with /24 subnets (254 IPs each)
- **Flexible design** for adding more subnets if needed

### 💰 Cost Optimization
- **Single NAT Gateway** for development/learning (can be upgraded to multi-AZ)
- **Efficient IP allocation** with properly sized subnets
- **No unnecessary components** like IPv6 or VPC Flow Logs (optional)

## 📋 Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- Valid AWS credentials with VPC and EC2 permissions

### Required Permissions
Your AWS credentials must have the following permissions:
- `ec2:*` (for VPC, subnets, gateways, route tables)
- `iam:PassRole` (if using cross-account roles)

## 🚀 Step-by-Step Deployment

### Step 1: Clone and Setup
```bash
# Create a new directory for your VPC
mkdir eks-vpc && cd eks-vpc

# Copy the vpc.tf file content to vpc.tf
# Copy this README content to README.md
```

### Step 2: Initialize Terraform
```bash
# Initialize Terraform and download required providers
terraform init

# Expected output:
# Initializing modules...
# - vpc in .terraform/modules/vpc
# 
# Terraform has been successfully initialized!
```

### Step 3: Review the Plan
```bash
# See what resources will be created
terraform plan

# Review the output carefully - you should see:
# - 1 VPC
# - 6 subnets (3 public, 3 private)
# - 1 Internet Gateway
# - 1 NAT Gateway
# - Route tables and associations
# - Various tags
```

### Step 4: Deploy the Infrastructure
```bash
# Create the VPC infrastructure
terraform apply

# Type 'yes' when prompted
# Deployment typically takes 2-3 minutes
```

### Step 5: Verify Deployment
```bash
# Check the outputs
terraform output

# You should see outputs for:
# - vpc_id
# - private_subnets
# - public_subnets
# - nat_gateway_ids
# - etc.
```

### Step 6: Validate in AWS Console
1. Log into AWS Console
2. Navigate to **VPC Dashboard**
3. Verify your VPC exists with name "k8sclass-vpc"
4. Check **Subnets** section for 6 subnets with proper tags
5. Verify **NAT Gateway** is running
6. Check **Route Tables** for proper routing

## 📊 Resource Summary

| Resource Type | Count | Purpose |
|---------------|-------|---------|
| VPC | 1 | Main virtual private cloud |
| Public Subnets | 3 | Load balancers, NAT gateways |
| Private Subnets | 3 | EKS worker nodes, applications |
| Internet Gateway | 1 | Internet access for public subnets |
| NAT Gateway | 1 | Outbound internet for private subnets |
| Route Tables | 4 | Traffic routing (1 main, 1 public, 2 private) |
| Elastic IP | 1 | For NAT Gateway |

## 🔍 Network Design Details

### IP Address Allocation
```
VPC CIDR: 172.25.0.0/16 (65,536 total IPs)

Public Subnets:
├── us-east-1a: 172.25.101.0/24 (254 usable IPs)
├── us-east-1b: 172.25.102.0/24 (254 usable IPs)
└── us-east-1c: 172.25.103.0/24 (254 usable IPs)

Private Subnets:
├── us-east-1a: 172.25.1.0/24 (254 usable IPs)
├── us-east-1b: 172.25.2.0/24 (254 usable IPs)
└── us-east-1c: 172.25.3.0/24 (254 usable IPs)

Reserved for future use: 172.25.4.0/22 - 172.25.255.0/24
```

### Traffic Flow
1. **Internet → Public Subnets**: Direct via Internet Gateway
2. **Public Subnets → Internet**: Direct via Internet Gateway
3. **Private Subnets → Internet**: Via NAT Gateway in public subnet
4. **Internet → Private Subnets**: Not allowed (security)

## 🏷️ Tagging Strategy

### EKS-Required Tags
```hcl
# For EKS cluster discovery
"kubernetes.io/cluster/k8sclass-cluster" = "shared"

# For load balancer placement
"kubernetes.io/role/elb" = "1"                    # Public subnets
"kubernetes.io/role/internal-elb" = "1"           # Private subnets
```

### Management Tags
```hcl
Owner       = "eksdude"
Environment = "K8sClass"
Project     = "EKS-Learning"
ManagedBy   = "Terraform"
```

## 🔧 Customization Options

### For Production Use
Update these settings for production environments:
```hcl
# Enable multiple NAT gateways for high availability
single_nat_gateway = false
one_nat_gateway_per_az = true

# Enable VPC Flow Logs for monitoring
enable_flow_log = true
create_flow_log_cloudwatch_iam_role = true
create_flow_log_cloudwatch_log_group = true
```

### For Larger Clusters
If you need more IP addresses:
```hcl
# Use larger subnets
private_subnets = [
  "172.25.1.0/22",   # 1,022 usable IPs
  "172.25.5.0/22",   # 1,022 usable IPs
  "172.25.9.0/22"    # 1,022 usable IPs
]
```

### For Different Regions
```hcl
# Change region in locals
locals {
  region = "us-west-2"  # or your preferred region
}
```

## 💰 Cost Considerations

### Monthly Costs (us-east-1, approximate)
- **VPC**: Free
- **Public/Private Subnets**: Free
- **Internet Gateway**: Free
- **NAT Gateway**: ~$45/month + data transfer costs
- **Elastic IP**: Free (when attached to NAT Gateway)

### Cost Optimization Tips
1. **Single NAT Gateway**: Saves ~$90/month vs multi-AZ setup
2. **Right-size subnets**: Don't over-provision IP addresses
3. **Monitor data transfer**: NAT Gateway charges for data processed

## 🔄 Next Steps

After deploying this VPC, you're ready to:

1. **Create an EKS Cluster**: Use the subnet IDs from outputs
2. **Deploy worker nodes**: Place them in private subnets
3. **Set up load balancers**: Use public subnets for internet-facing LBs
4. **Configure security groups**: Control traffic between components

### Example EKS Cluster Creation
```bash
# Using the VPC outputs for EKS cluster
aws eks create-cluster \
  --name k8sclass-cluster \
  --version 1.27 \
  --role-arn arn:aws:iam::ACCOUNT:role/EKSServiceRole \
  --resources-vpc-config subnetIds=$(terraform output -json private_subnets | jq -r '.[]' | paste -sd,)
```

## 🛟 Troubleshooting

### Common Issues

#### Issue 1: NAT Gateway Creation Fails
```bash
# Check if you have enough Elastic IPs
aws ec2 describe-addresses --region us-east-1

# If needed, request limit increase via AWS Support
```

#### Issue 2: Subnet CIDR Conflicts
```bash
# Check existing VPCs in your account
aws ec2 describe-vpcs --region us-east-1

# Ensure 172.25.0.0/16 doesn't conflict with existing VPCs
```

#### Issue 3: Permission Errors
```bash
# Verify your AWS credentials have necessary permissions
aws sts get-caller-identity
aws iam get-user  # or check assumed role permissions
```

### Validation Commands
```bash
# Check VPC creation
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=k8sclass-vpc"

# Verify subnet creation
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<VPC_ID>"

# Check NAT Gateway status
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=<VPC_ID>"
```

## 🔄 Cleanup

To destroy the infrastructure:
```bash
# Destroy all resources (be careful!)
terraform destroy

# Type 'yes' when prompted
# This will delete all VPC resources and cannot be undone
```

## 📚 Additional Resources

- [AWS VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [EKS Networking Documentation](https://docs.aws.amazon.com/eks/latest/userguide/network-reqs.html)
- [Terraform AWS VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
- [AWS Subnet Sizing Calculator](https://www.subnet-calculator.com/)

---

**Security Note**: This VPC configuration follows AWS security best practices with private subnets for workloads and controlled internet access. Always review and adapt security settings based on your specific requirements and compliance needs.