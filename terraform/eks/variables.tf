# =================================================================
# Core Configuration Variables
# =================================================================

variable "aws_region" {
  description = "AWS region for EKS cluster deployment"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "AWS region must be in the format: us-east-1, eu-west-1, etc."
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "k8sclass-cluster"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,99}$", var.cluster_name))
    error_message = "Cluster name must start with a letter, contain only alphanumeric characters and hyphens, and be 1-100 characters long."
  }
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "K8sClass"
  
  validation {
    condition     = contains(["Development", "Staging", "Production", "K8sClass"], var.environment)
    error_message = "Environment must be one of: Development, Staging, Production, K8sClass."
  }
}

variable "state_bucket" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
  default     = "k8sclass-tf-state-0625"
}

# =================================================================
# EKS Cluster Configuration
# =================================================================

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
  
  validation {
    condition = can(regex("^1\\.(2[4-9]|[3-9][0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.24 or higher (e.g., 1.28, 1.29, 1.30)."
  }
}

variable "cluster_endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
  validation {
    condition = alltrue([
      for cidr in var.cluster_endpoint_public_access_cidrs : 
      can(cidrhost(cidr, 0))
    ])
    error_message = "All elements must be valid CIDR blocks."
  }
}

# =================================================================
# Node Group Configuration
# =================================================================

variable "node_group_instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
  
  validation {
    condition = alltrue([
      for instance_type in var.node_group_instance_types :
      can(regex("^[a-z][0-9]+[a-z]*\\.[a-z0-9]+$", instance_type))
    ])
    error_message = "Instance types must be valid AWS instance types (e.g., t3.medium, m5.large)."
  }
}

variable "node_group_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group"
  type        = string
  default     = "AL2_x86_64"
  
  validation {
    condition = contains([
      "AL2_x86_64", 
      "AL2_x86_64_GPU", 
      "AL2_ARM_64", 
      "CUSTOM",
      "BOTTLEROCKET_ARM_64",
      "BOTTLEROCKET_x86_64"
    ], var.node_group_ami_type)
    error_message = "AMI type must be one of: AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM, BOTTLEROCKET_ARM_64, BOTTLEROCKET_x86_64."
  }
}

variable "node_group_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
  
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_group_capacity_type)
    error_message = "Capacity type must be either ON_DEMAND or SPOT."
  }
}

variable "node_group_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
  
  validation {
    condition     = var.node_group_disk_size >= 20 && var.node_group_disk_size <= 16384
    error_message = "Disk size must be between 20 and 16384 GiB."
  }
}

# =================================================================
# Node Group Scaling Configuration
# =================================================================

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
  
  validation {
    condition     = var.node_group_desired_size >= 1 && var.node_group_desired_size <= 1000
    error_message = "Desired size must be between 1 and 1000."
  }
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 6
  
  validation {
    condition     = var.node_group_max_size >= 1 && var.node_group_max_size <= 1000
    error_message = "Maximum size must be between 1 and 1000."
  }
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
  
  validation {
    condition     = var.node_group_min_size >= 0 && var.node_group_min_size <= 1000
    error_message = "Minimum size must be between 0 and 1000."
  }
}

variable "node_group_max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update"
  type        = number
  default     = 25
  
  validation {
    condition     = var.node_group_max_unavailable_percentage >= 1 && var.node_group_max_unavailable_percentage <= 100
    error_message = "Max unavailable percentage must be between 1 and 100."
  }
}

variable "node_group_bootstrap_arguments" {
  description = "Additional arguments for the EKS bootstrap script"
  type        = string
  default     = ""
}

# =================================================================
# Add-on Versions
# =================================================================

variable "vpc_cni_version" {
  description = "Version of the VPC CNI add-on"
  type        = string
  default     = "v1.15.1-eksbuild.1"
}

variable "coredns_version" {
  description = "Version of the CoreDNS add-on"
  type        = string
  default     = "v1.10.1-eksbuild.5"
}

variable "ebs_csi_driver_version" {
  description = "Version of the EBS CSI driver add-on"
  type        = string
  default     = "v1.24.0-eksbuild.1"
}

# =================================================================
# Logging and Monitoring Configuration
# =================================================================

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.cloudwatch_log_retention_days)
    error_message = "CloudWatch log retention must be one of the valid values: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653 days."
  }
}

# =================================================================
# Security Configuration
# =================================================================

variable "kms_key_deletion_window" {
  description = "Number of days to wait before deleting KMS keys"
  type        = number
  default     = 7
  
  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}