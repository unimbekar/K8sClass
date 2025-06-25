# =================================================================
# EKS-Ready VPC Configuration
# =================================================================
# This configuration creates a production-ready VPC for Amazon EKS
# with public and private subnets across multiple AZs, NAT gateways,
# and proper tagging for EKS subnet discovery.

# =================================================================
# Local Variables
# =================================================================
locals {
  # AWS region for deployment
  region = "us-east-1"
  
  # Common tags applied to all resources
  common_tags = {
    Owner       = "eksdude"
    Environment = "eks-network-upen"
    Project     = "EKS-Learning"
    ManagedBy   = "Terraform"
  }
  
  # EKS cluster name (used for subnet tagging)
  cluster_name = "eks-network-upen-cluster"
}

# =================================================================
# VPC Module Configuration
# =================================================================
# Using the community terraform-aws-modules/vpc module which provides
# a battle-tested, feature-rich VPC implementation with best practices.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"  # Use latest 5.x version for stability and features

  # =================================================================
  # Basic VPC Configuration
  # =================================================================
  name = "eks-network-upen-vpc"
  cidr = "172.25.0.0/16"  # Provides 65,536 IP addresses
  
  # =================================================================
  # Availability Zones
  # =================================================================
  # Deploy across 3 AZs for high availability and EKS requirements
  # EKS requires subnets in at least 2 AZs
  azs = [
    "${local.region}a",  # us-east-1a
    "${local.region}b",  # us-east-1b
    "${local.region}c"   # us-east-1c
  ]

  # =================================================================
  # Private Subnets Configuration
  # =================================================================
  # Private subnets for EKS worker nodes, databases, and internal services
  # Each subnet provides 254 usable IP addresses (256 - 2 reserved)
  private_subnets = [
    "172.25.1.0/24",   # AZ-a: 172.25.1.1 - 172.25.1.254
    "172.25.2.0/24",   # AZ-b: 172.25.2.1 - 172.25.2.254
    "172.25.3.0/24"    # AZ-c: 172.25.3.1 - 172.25.3.254
  ]
  
  # =================================================================
  # Public Subnets Configuration
  # =================================================================
  # Public subnets for NAT gateways, load balancers, and bastion hosts
  # Each subnet provides 254 usable IP addresses
  public_subnets = [
    "172.25.101.0/24", # AZ-a: 172.25.101.1 - 172.25.101.254
    "172.25.102.0/24", # AZ-b: 172.25.102.1 - 172.25.102.254
    "172.25.103.0/24"  # AZ-c: 172.25.103.1 - 172.25.103.254
  ]

  # =================================================================
  # NAT Gateway Configuration
  # =================================================================
  # Enable NAT gateways to allow private subnet resources to reach the internet
  # This is REQUIRED for EKS worker nodes to:
  # - Pull container images from public registries
  # - Download packages and updates
  # - Communicate with EKS control plane APIs
  enable_nat_gateway = true
  
  # Use single NAT gateway for cost optimization in development/learning environments
  # For production, set to false to create one NAT gateway per AZ (higher availability)
  single_nat_gateway = true
  
  # Place NAT gateway in first public subnet only (when single_nat_gateway = true)
  one_nat_gateway_per_az = false

  # =================================================================
  # Internet Gateway Configuration
  # =================================================================
  # Automatically creates and attaches an Internet Gateway for public subnet access
  create_igw = true

  # =================================================================
  # DNS Configuration
  # =================================================================
  # Enable DNS hostnames and resolution for EKS cluster communication
  enable_dns_hostnames = true
  enable_dns_support   = true

  # =================================================================
  # VPC Flow Logs (Optional - for monitoring and troubleshooting)
  # =================================================================
  # Uncomment to enable VPC Flow Logs for network traffic monitoring
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  # =================================================================
  # Subnet Tagging for EKS
  # =================================================================
  # These tags are REQUIRED for EKS to automatically discover subnets
  
  # Public subnet tags - for internet-facing load balancers
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"  # Required for external load balancers
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    Type = "Public"
  }

  # Private subnet tags - for internal load balancers and worker nodes
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"  # Required for internal load balancers
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    Type = "Private"
  }

  # =================================================================
  # Resource Tagging
  # =================================================================
  # Apply common tags to all VPC resources
  tags = merge(local.common_tags, {
    Name        = "eks-network-upen-vpc"
    Description = "VPC for EKS learning environment"
  })

  # VPC-specific tags
  vpc_tags = merge(local.common_tags, {
    Name = "eks-network-upen-vpc"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  })

  # Internet Gateway tags
  igw_tags = merge(local.common_tags, {
    Name = "eks-network-upen-igw"
  })

  # NAT Gateway tags
  nat_gateway_tags = merge(local.common_tags, {
    Name = "eks-network-upen-nat"
  })

  # Route table tags
  public_route_table_tags = merge(local.common_tags, {
    Name = "eks-network-upen-public-rt"
  })

  private_route_table_tags = merge(local.common_tags, {
    Name = "eks-network-upen-private-rt"
  })
}
