output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster."
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster."
  value       = aws_eks_cluster.main.arn
}

output "oidc_provider_url" {
  description = "The URL of the EKS OIDC provider."
  value       = aws_iam_openid_connect_provider.eks.url
}

output "oidc_provider_arn" {
  description = "The ARN of the EKS OIDC provider."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "cluster_security_group_id" {
  description = "EKS-managed cluster security group — used to allow VPN ingress from GCP."
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}
