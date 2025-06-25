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
  description = "The cluster primary security