# =================================================================
# EKS Cluster Outputs
# =================================================================
# These outputs provide essential information about the created EKS cluster
# and its components for use by other Terraform configurations or scripts

# =================================================================
# Cluster Information
# =================================================================

output "cluster_id" {
  description = "The ID/name of the EKS cluster"
  value       = aws_eks_cluster.cluster.id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.cluster.arn
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version for the EKS cluster"
  value       = aws_eks_cluster.cluster.version
}

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = aws_eks_cluster.cluster.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster (CREATING, ACTIVE, DELETING, FAILED)"
  value       = aws_eks_cluster.cluster.status
}

# =================================================================
# Cluster Certificate Authority
# =================================================================

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

# =================================================================
# Security Groups
# =================================================================

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster_security_group.id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS node group"
  value       = aws_security_group.node_group_security_group.id
}

output "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by EKS"
  value       = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

# =================================================================
# Node Group Information
# =================================================================

output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "Status of the EKS Node Group"
  value       = aws_eks_node_group.main.status
}

output "node_group_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group"
  value       = aws_eks_node_group.main.capacity_type
}

output "node_group_instance_types" {
  description = "Set of instance types associated with the EKS Node Group"
  value       = aws_eks_node_group.main.instance_types
}

output "node_group_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group"
  value       = aws_eks_node_group.main.ami_type
}

output "node_group_remote_access_ec2_ssh_key" {
  description = "EC2 Key Pair name that provides access for SSH communication with the worker nodes"
  value       = try(aws_eks_node_group.main.remote_access[0].ec2_ssh_key, null)
}

# =================================================================
# OIDC Identity Provider
# =================================================================

output "oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Identity Provider if enabled"
  value       = aws_iam_openid_connect_provider.eks.arn
}

# =================================================================
# CloudWatch and Logging
# =================================================================

output "cloudwatch_log_group_name" {
  description = "Name of cloudwatch log group for EKS cluster logs"
  value       = aws_cloudwatch_log_group.eks_cluster_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of cloudwatch log group for EKS cluster logs"
  value       = aws_cloudwatch_log_group.eks_cluster_logs.arn
}

# =================================================================
# KMS Keys
# =================================================================

output "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key for secrets encryption"
  value       = aws_kms_key.eks_secrets.arn
}

output "kms_key_id" {
  description = "The globally unique identifier for the KMS key for secrets encryption"
  value       = aws_kms_key.eks_secrets.key_id
}

# =================================================================
# Add-ons Information
# =================================================================

output "vpc_cni_addon_arn" {
  description = "Amazon Resource Name (ARN) of the VPC CNI EKS add-on"
  value       = aws_eks_addon.vpc_cni.arn
}

output "coredns_addon_arn" {
  description = "Amazon Resource Name (ARN) of the CoreDNS EKS add-on"
  value       = aws_eks_addon.coredns.arn
}

output "ebs_csi_addon_arn" {
  description = "Amazon Resource Name (ARN) of the EBS CSI EKS add-on"
  value       = aws_eks_addon.ebs_csi_driver.arn
}

# =================================================================
# kubectl Configuration
# =================================================================

output "kubectl_config" {
  description = "kubectl config as generated by the module"
  value = {
    cluster_name                     = aws_eks_cluster.cluster.name
    endpoint                        = aws_eks_cluster.cluster.endpoint
    ca_data                         = aws_eks_cluster.cluster.certificate_authority[0].data
    region                          = var.aws_region
    cluster_arn                     = aws_eks_cluster.cluster.arn
  }
  sensitive = false
}

# =================================================================
# Connection Commands
# =================================================================

output "cluster_connect_command" {
  description = "AWS CLI command to configure kubectl for this cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.cluster.name}"
}

# =================================================================
# Useful URLs and Information
# =================================================================

output "cluster_console_url" {
  description = "AWS Console URL for the EKS cluster"
  value       = "https://console.aws.amazon.com/eks/home?region=${var.aws_region}#/clusters/${aws_eks_cluster.cluster.name}"
}

# =================================================================
# Network Information
# =================================================================

output "cluster_vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = aws_eks_cluster.cluster.vpc_config[0].vpc_id
}

output "cluster_subnet_ids" {
  description = "List of subnet IDs where the cluster is deployed"
  value       = aws_eks_cluster.cluster.vpc_config[0].subnet_ids
}