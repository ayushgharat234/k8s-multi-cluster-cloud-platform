output "eks_cluster_name" {
  description = "Name of the EKS spoke cluster."
  value       = module.eks_spoke.cluster_name
}

output "eks_cluster_endpoint" {
  description = "API endpoint of the EKS spoke cluster."
  value       = module.eks_spoke.cluster_endpoint
  sensitive   = true
}

output "oidc_provider_url" {
  description = "EKS OIDC issuer URL — pass this as eks_oidc_url to infra/gcp."
  value       = module.eks_spoke.oidc_provider_url
}

output "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider (for IRSA bindings)."
  value       = module.eks_spoke.oidc_provider_arn
}

output "ci_role_arn" {
  description = "ARN of the GitHub Actions CI/CD IAM role."
  value       = module.identity.ci_role_arn
}
