# =================================================================
# Terraform and Provider Version Requirements
# =================================================================

terraform {
  # Minimum Terraform version required
  required_version = ">= 1.0"

  # Required providers with version constraints
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# =================================================================
# Provider Configuration
# =================================================================

provider "aws" {
  region = var.aws_region
  
  # Use IAM role for EKS operations (from IAM Terraform state)
  assume_role {
    role_arn = data.terraform_remote_state.iam.outputs.iam.eks_dude_role.arn
  }

  # Default tags applied to all resources
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "EKS-Learning"
      ManagedBy   = "Terraform"
      Owner       = "eksdude"
    }
  }
}