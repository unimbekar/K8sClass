variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-network-upen-cluster"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "eks-network-upen"
}