# =================================================================
# EKS Cluster Configuration Example
# =================================================================
# Copy this file to terraform.tfvars and customize the values
# for your specific environment and requirements.

# =================================================================
# Core Configuration
# =================================================================

# AWS region for deployment
aws_region = "us-east-1"

# Name of the EKS cluster
cluster_name = "k8sclass-cluster"

# Environment tag
environment = "K8sClass"

# S3 bucket for Terraform state (should match your setup)
state_bucket = "k8sclass-tf-state-0625"

# =================================================================
# EKS Cluster Configuration
# =================================================================

# Kubernetes version (use latest stable)
kubernetes_version = "1.29"

# Public API endpoint access (set to false for private-only access)
cluster_endpoint_public_access = true

# CIDR blocks allowed to access public API (restrict for security)
cluster_endpoint_public_access_cidrs = [
  "98.188.155.226/32"  # Change this to your IP range for better security
  # "203.0.113.0/24"  # Example: Your office IP range
]

# =================================================================
# Worker Node Configuration
# =================================================================

# Instance types for worker nodes
node_group_instance_types = ["t3.medium"]

# AMI type for worker nodes
node_group_ami_type = "CUSTOM"

# Capacity type (ON_DEMAND for stability, SPOT for cost savings)
node_group_capacity_type = "ON_DEMAND"

# Root volume size for worker nodes (in GiB)
node_group_disk_size = 30

# =================================================================
# Auto Scaling Configuration
# =================================================================

# Number of worker nodes to maintain
node_group_desired_size = 2

# Maximum number of worker nodes
node_group_max_size = 6

# Minimum number of worker nodes
node_group_min_size = 1

# Maximum percentage of nodes unavailable during updates
node_group_max_unavailable_percentage = 25

# Additional bootstrap arguments (optional)
node_group_bootstrap_arguments = "--container-runtime containerd"

# =================================================================
# Add-on Versions (use latest compatible versions)
# =================================================================

# VPC CNI version for pod networking
vpc_cni_version = "v1.15.1-eksbuild.1"

# CoreDNS version for DNS resolution
coredns_version = "v1.10.1-eksbuild.5"

# EBS CSI driver version for persistent volumes
ebs_csi_driver_version = "v1.24.0-eksbuild.1"

# =================================================================
# Logging and Monitoring
# =================================================================

# CloudWatch log retention period (days)
cloudwatch_log_retention_days = 7

# =================================================================
# Security Configuration
# =================================================================

# KMS key deletion window (days)
kms_key_deletion_window = 7

# =================================================================
# Alternative Configurations for Different Environments
# =================================================================

# Development Environment Example:
# node_group_instance_types = ["t3.small"]
# node_group_desired_size = 1
# node_group_max_size = 3
# node_group_capacity_type = "SPOT"  # For cost savings
# cloudwatch_log_retention_days = 3

# Production Environment Example:
# node_group_instance_types = ["m5.large", "m5.xlarge"]
# node_group_desired_size = 3
# node_group_max_size = 10
# node_group_capacity_type = "ON_DEMAND"
# cluster_endpoint_public_access = false  # Private API endpoint only
# cloudwatch_log_retention_days = 30
# kms_key_deletion_window = 30

# High Performance Example:
# node_group_instance_types = ["c5.2xlarge"]
# node_group_disk_size = 50
# node_group_desired_size = 3
# node_group_max_size = 20

# GPU Workloads Example:
# node_group_instance_types = ["g4dn.xlarge"]
# node_group_ami_type = "AL2_x86_64_GPU"
# node_group_disk_size = 100

# ARM-based Instances Example:
# node_group_instance_types = ["m6g.medium"]
# node_group_ami_type = "AL2_ARM_64"