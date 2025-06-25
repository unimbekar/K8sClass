# =================================================================
# EKS Cluster Configuration
# =================================================================
# This configuration creates a production-ready EKS cluster with:
# - Secure worker node placement in private subnets
# - Proper security groups and network access controls
# - Essential add-ons and logging enabled
# - Multi-AZ deployment for high availability

# =================================================================
# Remote State Data Sources
# =================================================================
# Import IAM roles and policies from the IAM Terraform state
data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    region = var.aws_region
    bucket = var.state_bucket
    key    = "iam/terraform.tfstate"
  }
}

# Import VPC and networking configuration from the VPC Terraform state
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = var.aws_region
    bucket = var.state_bucket
    key    = "network/terraform.tfstate"
  }
}

# =================================================================
# Local Variables
# =================================================================
locals {
  # Extract remote state outputs with proper error handling
  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets
  public_subnet_ids  = data.terraform_remote_state.vpc.outputs.public_subnets
  
  # IAM role ARNs from remote state
  cluster_service_role_arn = data.terraform_remote_state.iam.outputs.eks_service_role_arn
  node_group_role_arn     = data.terraform_remote_state.iam.outputs.eks_node_group_role_arn
  
  # Common tags for all EKS resources
  common_tags = {
    Environment   = var.environment
    Project      = "EKS-Learning"
    Owner        = "eksdude"
    ManagedBy    = "Terraform"
    Cluster      = var.cluster_name
  }
}

# =================================================================
# EKS Cluster Security Group
# =================================================================
# Additional security group for EKS cluster with specific rules
resource "aws_security_group" "cluster_security_group" {
  name_prefix = "${var.cluster_name}-cluster-sg-"
  description = "Security group for EKS cluster control plane"
  vpc_id      = local.vpc_id

  # Allow HTTPS traffic from worker nodes to cluster API
  ingress {
    description = "HTTPS from worker nodes"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.25.0.0/16"]  # Updated CIDR range
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-cluster-sg"
    Type = "EKS-Cluster-SecurityGroup"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =================================================================
# Worker Node Security Group
# =================================================================
# Security group for EKS worker nodes
resource "aws_security_group" "node_group_security_group" {
  name_prefix = "${var.cluster_name}-node-sg-"
  description = "Security group for EKS worker nodes"
  vpc_id      = local.vpc_id

  # Allow worker nodes to communicate with each other
  ingress {
    description = "Node-to-node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Allow worker nodes to receive traffic from cluster
  ingress {
    description     = "Cluster to node communication"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster_security_group.id]
  }

  # Allow HTTPS traffic from cluster to nodes
  ingress {
    description     = "HTTPS from cluster"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster_security_group.id]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-node-sg"
    Type = "EKS-Node-SecurityGroup"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =================================================================
# EKS Cluster
# =================================================================
# Main EKS cluster configuration
resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = local.cluster_service_role_arn
  version  = var.kubernetes_version

  # VPC Configuration - cluster endpoint in public subnets for accessibility
  vpc_config {
    subnet_ids              = concat(local.private_subnet_ids, local.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = [aws_security_group.cluster_security_group.id]
  }

  # Enable comprehensive logging for monitoring and troubleshooting
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Encryption configuration for secrets
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_secrets.arn
    }
    resources = ["secrets"]
  }

  tags = merge(local.common_tags, {
    Name = var.cluster_name
    Type = "EKS-Cluster"
  })

  # Ensure IAM roles are created before cluster
  depends_on = [
    aws_cloudwatch_log_group.eks_cluster_logs
  ]

  lifecycle {
    ignore_changes = [
      # Ignore changes to log retention to prevent plan differences
      enabled_cluster_log_types
    ]
  }
}

# =================================================================
# CloudWatch Log Group for EKS Cluster Logs
# =================================================================
resource "aws_cloudwatch_log_group" "eks_cluster_logs" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = aws_kms_key.eks_logs.arn

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-cluster-logs"
    Type = "EKS-CloudWatch-LogGroup"
  })
}

# =================================================================
# KMS Keys for Encryption
# =================================================================
# KMS key for EKS secrets encryption
resource "aws_kms_key" "eks_secrets" {
  description             = "KMS key for EKS secrets encryption"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-secrets-key"
    Type = "EKS-KMS-Key"
  })
}

resource "aws_kms_alias" "eks_secrets" {
  name          = "alias/${var.cluster_name}-secrets"
  target_key_id = aws_kms_key.eks_secrets.key_id
}

# KMS key for CloudWatch logs encryption
resource "aws_kms_key" "eks_logs" {
  description             = "KMS key for EKS CloudWatch logs encryption"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-logs-key"
    Type = "EKS-KMS-Key"
  })
}

resource "aws_kms_alias" "eks_logs" {
  name          = "alias/${var.cluster_name}-logs"
  target_key_id = aws_kms_key.eks_logs.key_id
}

# =================================================================
# EKS Node Group
# =================================================================
# Managed node group for EKS worker nodes
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.cluster_name}-main-nodes"
  node_role_arn   = local.node_group_role_arn
  
  # IMPORTANT: Place worker nodes in PRIVATE subnets for security
  subnet_ids = local.private_subnet_ids

  # Instance configuration
  instance_types = var.node_group_instance_types
  ami_type       = var.node_group_ami_type
  capacity_type  = var.node_group_capacity_type
  disk_size      = var.node_group_disk_size

  # Scaling configuration
  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  # Update configuration
  update_config {
    max_unavailable_percentage = var.node_group_max_unavailable_percentage
  }

  # Launch template configuration
  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-main-nodes"
    Type = "EKS-NodeGroup"
  })

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size,
      launch_template[0].version
    ]
  }

  # Ensure dependencies are met
  depends_on = [
    aws_eks_cluster.cluster
  ]
}

# =================================================================
# Launch Template for Worker Nodes
# =================================================================
resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "${var.cluster_name}-node-template-"
  description   = "Launch template for EKS worker nodes"
  image_id      = data.aws_ssm_parameter.eks_ami_release_version.value
  instance_type = var.node_group_instance_types[0]

  vpc_security_group_ids = [aws_security_group.node_group_security_group.id]

  # User data for node initialization
  user_data = base64encode(templatefile("${path.module}/templates/userdata.sh", {
    cluster_name        = aws_eks_cluster.cluster.name
    cluster_endpoint    = aws_eks_cluster.cluster.endpoint
    cluster_ca          = aws_eks_cluster.cluster.certificate_authority[0].data
    bootstrap_arguments = var.node_group_bootstrap_arguments
  }))

  # Block device mapping
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_group_disk_size
      volume_type          = "gp3"
      encrypted            = true
      delete_on_termination = true
    }
  }

  # Instance metadata service configuration
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.cluster_name}-worker-node"
      Type = "EKS-WorkerNode"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-node-template"
    Type = "EKS-LaunchTemplate"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =================================================================
# Data Sources
# =================================================================
# Get the latest EKS optimized AMI
data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${var.kubernetes_version}/amazon-linux-2/recommended/image_id"
}

# =================================================================
# EKS Add-ons
# =================================================================
# Essential EKS add-ons for cluster functionality

# VPC CNI add-on for pod networking
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.cluster.name
  addon_name               = "vpc-cni"
  addon_version            = var.vpc_cni_version
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.vpc_cni_role.arn

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-vpc-cni"
    Type = "EKS-Addon"
  })

  depends_on = [
    aws_eks_node_group.main
  ]
}

# CoreDNS add-on for DNS resolution
resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.cluster.name
  addon_name        = "coredns"
  addon_version     = var.coredns_version
  resolve_conflicts = "OVERWRITE"

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-coredns"
    Type = "EKS-Addon"
  })

  depends_on = [
    aws_eks_node_group.main
  ]
}

# EBS CSI driver for persistent volume support
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.ebs_csi_driver_version
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-ebs-csi"
    Type = "EKS-Addon"
  })

  depends_on = [
    aws_eks_node_group.main
  ]
}

# =================================================================
# IAM Roles for Add-ons
# =================================================================
# IAM role for VPC CNI add-on
resource "aws_iam_role" "vpc_cni_role" {
  name = "${var.cluster_name}-vpc-cni-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-node"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-vpc-cni-role"
    Type = "EKS-ServiceRole"
  })
}

resource "aws_iam_role_policy_attachment" "vpc_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni_role.name
}

# IAM role for EBS CSI driver
resource "aws_iam_role" "ebs_csi_role" {
  name = "${var.cluster_name}-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-ebs-csi-role"
    Type = "EKS-ServiceRole"
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/Amazon_EBS_CSI_DriverPolicy"
  role       = aws_iam_role.ebs_csi_role.name
}

# =================================================================
# OIDC Identity Provider
# =================================================================
# OIDC provider for service account role assumption
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-oidc-provider"
    Type = "EKS-OIDC-Provider"
  })
}