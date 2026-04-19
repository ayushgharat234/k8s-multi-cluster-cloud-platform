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

# --- VPN outputs (only populated when gcp_vpn_gateway_ip is set) ---
output "vpn_tunnel1_address" {
  value = length(module.vpn) > 0 ? module.vpn[0].tunnel1_address : ""
}
output "vpn_tunnel1_preshared_key" {
  value     = length(module.vpn) > 0 ? module.vpn[0].tunnel1_preshared_key : ""
  sensitive = true
}
output "vpn_tunnel1_cgw_inside_address" {
  value = length(module.vpn) > 0 ? module.vpn[0].tunnel1_cgw_inside_address : ""
}
output "vpn_tunnel1_vgw_inside_address" {
  value = length(module.vpn) > 0 ? module.vpn[0].tunnel1_vgw_inside_address : ""
}
output "vpn_tunnel2_address" {
  value = length(module.vpn) > 0 ? module.vpn[0].tunnel2_address : ""
}
output "vpn_tunnel2_preshared_key" {
  value     = length(module.vpn) > 0 ? module.vpn[0].tunnel2_preshared_key : ""
  sensitive = true
}
output "vpn_tunnel2_cgw_inside_address" {
  value = length(module.vpn) > 0 ? module.vpn[0].tunnel2_cgw_inside_address : ""
}
output "vpn_tunnel2_vgw_inside_address" {
  value = length(module.vpn) > 0 ? module.vpn[0].tunnel2_vgw_inside_address : ""
}
