# =================================================================
# Outputs
# =================================================================
output "eks_service_role_arn" {
  description = "ARN of the EKS service role"
  value       = aws_iam_role.EKSServiceRole.arn
}

output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group role"
  value       = aws_iam_role.eks_node_group.arn
}

output "eks_dude_role_arn" {
  description = "ARN of the eks_dude_role"
  value       = aws_iam_role.eks_dude_role.arn
}

output "eks_user_access_key" {
  description = "Access key for eksdude user"
  value       = aws_iam_access_key.eksdude.id
}

output "eks_user_secret_key" {
  description = "Secret key for eksdude user"
  value       = aws_iam_access_key.eksdude.secret
  sensitive   = true
}

output "eks_user_password" {
  description = "Password for eksdude user console access"
  value       = aws_iam_user_login_profile.eksdude.password
  sensitive   = true
}