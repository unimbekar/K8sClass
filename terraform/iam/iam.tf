# =================================================================
# Complete IAM Configuration for EKS
# =================================================================
# This configuration creates a comprehensive IAM setup for EKS operations
# including all necessary permissions for CloudWatch, KMS, and EKS services.

# =================================================================
# Provider Configuration
# =================================================================
provider "aws" {
  region = "us-east-1"
}

# =================================================================
# Data Sources
# =================================================================
data "aws_caller_identity" "current" {}

# =================================================================
# EKS Full Access Policy
# =================================================================
data "aws_iam_policy_document" "EKSFullAccess" {
  statement {
    sid = "EKSFullAccess"
    actions = [
      "eks:*",
      "ecr:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "EKSFullAccess" {
  name   = "EKSFullAccess"
  path   = "/"
  policy = data.aws_iam_policy_document.EKSFullAccess.json
  
  tags = {
    Name        = "EKSFullAccess"
    Description = "Full access to EKS and ECR services"
  }
}

# =================================================================
# KMS Access Policy
# =================================================================
data "aws_iam_policy_document" "KMSAccess" {
  statement {
    sid = "KMSAccess"
    actions = [
      "kms:CreateKey",
      "kms:CreateAlias",
      "kms:DeleteAlias",
      "kms:DescribeKey",
      "kms:EnableKeyRotation",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListAliases",
      "kms:ListKeys",
      "kms:TagResource",
      "kms:ListResourceTags",
      "kms:UntagResource",
      "kms:UpdateAlias",
      "kms:UpdateKeyDescription",
      "kms:PutKeyPolicy",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "KMSAccess" {
  name   = "KMSAccess"
  path   = "/"
  policy = data.aws_iam_policy_document.KMSAccess.json
  
  tags = {
    Name        = "KMSAccess"
    Description = "KMS key management permissions"
  }
}

# =================================================================
# CloudWatch Logs Access Policy
# =================================================================
data "aws_iam_policy_document" "CloudWatchLogsAccess" {
  statement {
    sid = "CloudWatchLogsAccess"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:DeleteLogGroup",
      "logs:DeleteLogStream",
      "logs:PutRetentionPolicy",
      "logs:TagLogGroup",
      "logs:UntagLogGroup",
      "logs:ListTagsLogGroup",
      "logs:FilterLogEvents",
      "logs:GetLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*",
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*:*"
    ]
  }
}

resource "aws_iam_policy" "CloudWatchLogsAccess" {
  name   = "CloudWatchLogsAccess"
  path   = "/"
  policy = data.aws_iam_policy_document.CloudWatchLogsAccess.json
  
  tags = {
    Name        = "CloudWatchLogsAccess"
    Description = "CloudWatch Logs management permissions"
  }
}

# =================================================================
# IAM Pass Role Policy (Enhanced with FIXED SSM access)
# =================================================================
data "aws_iam_policy_document" "iamPassRole" {
  statement {
    sid = "IAMRoleManagement"
    actions = [
      "iam:PassRole",
      "iam:GetRole",
      "iam:CreateServiceLinkedRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
    ]
  }

  statement {
    sid = "IAMPolicyManagement"
    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:GetPolicy",
      "iam:ListPolicies",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/*"
    ]
  }

  statement {
    sid = "IAMInstanceProfileManagement"
    actions = [
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:ListInstanceProfiles"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
    ]
  }

  statement {
    sid = "OIDCProviderManagement"
    actions = [
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider",
      "iam:ListOpenIDConnectProviders",
      "iam:TagOpenIDConnectProvider",
      "iam:UntagOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/*"
    ]
  }

  statement {
    sid = "ServiceLinkedRoleManagement"
    actions = [
      "iam:DeleteServiceLinkedRole",
      "iam:GetServiceLinkedRoleDeletionStatus"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/*"
    ]
  }

  statement {
    sid = "SSMParameterAccess"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters"
    ]
    resources = [
      # AWS service parameters (no account ID in ARN)
      "arn:aws:ssm:*::parameter/aws/service/eks/optimized-ami/*",
      "arn:aws:ssm:us-east-1::parameter/aws/service/eks/optimized-ami/*",
      # Your account parameters
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/*"
    ]
  }
}

resource "aws_iam_policy" "iamPassRole" {
  name   = "iamPassRole"
  path   = "/"
  policy = data.aws_iam_policy_document.iamPassRole.json
  
  tags = {
    Name        = "iamPassRole"
    Description = "IAM role and policy management permissions including SSM access"
  }
}

# =================================================================
# Cluster Autoscaling Policy
# =================================================================
data "aws_iam_policy_document" "EKSClusterAutoscaling" {
  statement {
    sid = "EKSClusterAutoscaling"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeInstanceTypes"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "EKSClusterAutoscaling" {
  name   = "EKSClusterAutoscaling"
  path   = "/"
  policy = data.aws_iam_policy_document.EKSClusterAutoscaling.json
  
  tags = {
    Name        = "EKSClusterAutoscaling"
    Description = "Auto Scaling permissions for EKS cluster"
  }
}

# =================================================================
# EKS Demo Group
# =================================================================
resource "aws_iam_group" "EKSDemoGroup" {
  name = "EKSDemoGroup"
  path = "/"  
}

# =================================================================
# AWS Managed Policy Attachments to Group (REDUCED to fit limit)
# =================================================================
resource "aws_iam_group_policy_attachment" "AmazonEC2FullAccess" {
  group      = aws_iam_group.EKSDemoGroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_group_policy_attachment" "AmazonVPCFullAccess" {
  group      = aws_iam_group.EKSDemoGroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_group_policy_attachment" "IAMReadOnlyAccess" {
  group      = aws_iam_group.EKSDemoGroup.name
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

# =================================================================
# Custom Policy Attachments to Group (REDUCED to fit limit)
# =================================================================
resource "aws_iam_group_policy_attachment" "EKSFullAccess" {
  group      = aws_iam_group.EKSDemoGroup.name
  policy_arn = aws_iam_policy.EKSFullAccess.arn
}

resource "aws_iam_group_policy_attachment" "KMSAccess" {
  group      = aws_iam_group.EKSDemoGroup.name
  policy_arn = aws_iam_policy.KMSAccess.arn
}

resource "aws_iam_group_policy_attachment" "CloudWatchLogsAccess" {
  group      = aws_iam_group.EKSDemoGroup.name
  policy_arn = aws_iam_policy.CloudWatchLogsAccess.arn
}

resource "aws_iam_group_policy_attachment" "iamPassRole" {
  group      = aws_iam_group.EKSDemoGroup.name
  policy_arn = aws_iam_policy.iamPassRole.arn
}

# =================================================================
# EKS Demo User
# =================================================================
resource "aws_iam_user" "eksdude" {
  name          = "eksdude"
  force_destroy = true
  
  tags = {
    Name        = "eksdude"
    Description = "EKS demo user"
    Environment = "K8sClass"
  }
}

resource "aws_iam_user_group_membership" "eksdude" {
  user = aws_iam_user.eksdude.name
  groups = [
    aws_iam_group.EKSDemoGroup.name
  ]
}

# Console access policy for user
data "aws_iam_policy_document" "eksdude_console" {
  statement {
    sid = "ConsoleAccess"
    actions = [
      "iam:ChangePassword",
      "iam:GetAccountPasswordPolicy"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.eksdude.name}"
    ]
  }
}

resource "aws_iam_user_policy" "eksdude_console" {
  name   = "ConsolePolicy"
  user   = aws_iam_user.eksdude.name
  policy = data.aws_iam_policy_document.eksdude_console.json
}

# User login profile (without PGP encryption for now)
resource "aws_iam_user_login_profile" "eksdude" {
  user            = aws_iam_user.eksdude.name
  password_length = 12

  lifecycle {
    ignore_changes = [password_length, password_reset_required]
  }
}

# Access keys (without PGP encryption for now)
resource "aws_iam_access_key" "eksdude" {
  user = aws_iam_user.eksdude.name
}

# =================================================================
# EKS Service Role
# =================================================================
resource "aws_iam_role" "EKSServiceRole" {
  name = "EKSServiceRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name        = "EKSServiceRole"
    Description = "Service role for EKS cluster"
    Environment = "K8sClass"
  }
}

resource "aws_iam_role_policy_attachment" "EKSServiceRole_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.EKSServiceRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# =================================================================
# EKS Node Group Role
# =================================================================
resource "aws_iam_role" "eks_node_group" {
  name = "eks_node_group"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.eks_dude_role.arn
        }
      }
    ]
  })
  
  tags = {
    Name        = "eks_node_group"
    Description = "IAM role for EKS node group"
    Environment = "K8sClass"
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_node_group_autoscaling" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = aws_iam_policy.EKSClusterAutoscaling.arn
}

# =================================================================
# EKS Dude Role (Main role for EKS operations)
# =================================================================
data "aws_iam_policy_document" "eks_dude_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.eksdude.arn]
    }
  }
  
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "eks_dude_role" {
  name               = "eks_dude_role"
  assume_role_policy = data.aws_iam_policy_document.eks_dude_assume_role_policy.json
  
  tags = {
    Name        = "eks_dude_role"
    Description = "Main role for EKS cluster operations"
    Environment = "K8sClass"
  }
}

# Attach all necessary policies to eks_dude_role
resource "aws_iam_role_policy_attachment" "eks_dude_role_ec2" {
  role       = aws_iam_role.eks_dude_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "eks_dude_role_vpc" {
  role       = aws_iam_role.eks_dude_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "eks_dude_role_iam_pass" {
  role       = aws_iam_role.eks_dude_role.name
  policy_arn = aws_iam_policy.iamPassRole.arn
}

resource "aws_iam_role_policy_attachment" "eks_dude_role_eks_full" {
  role       = aws_iam_role.eks_dude_role.name
  policy_arn = aws_iam_policy.EKSFullAccess.arn
}

resource "aws_iam_role_policy_attachment" "eks_dude_role_kms" {
  role       = aws_iam_role.eks_dude_role.name
  policy_arn = aws_iam_policy.KMSAccess.arn
}

resource "aws_iam_role_policy_attachment" "eks_dude_role_cloudwatch" {
  role       = aws_iam_role.eks_dude_role.name
  policy_arn = aws_iam_policy.CloudWatchLogsAccess.arn
}

resource "aws_iam_role_policy_attachment" "eks_dude_role_autoscaling" {
  role       = aws_iam_role.eks_dude_role.name
  policy_arn = aws_iam_policy.EKSClusterAutoscaling.arn
}
