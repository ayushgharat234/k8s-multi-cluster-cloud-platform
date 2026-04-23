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

# --- VPN outputs (only populated when gcp_vpn_interface_0_ip is set) ---
# Connection 1 (TGW ↔ CGW1 / GCP interface 0) — tunnel-1 & tunnel-2 on GCP side
output "vpn_conn1_t1_outside_ip" {
  value = length(module.vpn) > 0 ? module.vpn[0].conn1_t1_outside_ip : ""
}
output "vpn_conn1_t1_cgw_inside_address" {
  description = "Append /30 when setting aws_conn1_t1_cgw_inside in infra/gcp/terraform.tfvars."
  value = length(module.vpn) > 0 ? module.vpn[0].conn1_t1_cgw_inside_address : ""
}
output "vpn_conn1_t1_vgw_inside_address" {
  value = length(module.vpn) > 0 ? module.vpn[0].conn1_t1_vgw_inside_address : ""
}

output "vpn_conn1_t2_outside_ip" {
  value = length(module.vpn) > 0 ? module.vpn[0].conn1_t2_outside_ip : ""
}
output "vpn_conn1_t2_cgw_inside_address" {
  description = "Append /30 when setting aws_conn1_t2_cgw_inside in infra/gcp/terraform.tfvars."
  value = length(module.vpn) > 0 ? module.vpn[0].conn1_t2_cgw_inside_address : ""
}
output "vpn_conn1_t2_vgw_inside_address" {
  value = length(module.vpn) > 0 ? module.vpn[0].conn1_t2_vgw_inside_address : ""
}

# Connection 2 (TGW ↔ CGW2 / GCP interface 1) — tunnel-3 & tunnel-4 on GCP side
output "vpn_conn2_t1_outside_ip" {
  value = length(module.vpn) > 0 ? module.vpn[0].conn2_t1_outside_ip : ""
}
output "vpn_conn2_t1_cgw_inside_address" {
  description = "Append /30 when setting aws_conn2_t1_cgw_inside in infra/gcp/terraform.tfvars."
  value = length(module.vpn) > 0 ? module.vpn[0].conn2_t1_cgw_inside_address : ""
}
output "vpn_conn2_t1_vgw_inside_address" {
  value = length(module.vpn) > 0 ? module.vpn[0].conn2_t1_vgw_inside_address : ""
}

output "vpn_conn2_t2_outside_ip" {
  value = length(module.vpn) > 0 ? module.vpn[0].conn2_t2_outside_ip : ""
}
output "vpn_conn2_t2_cgw_inside_address" {
  description = "Append /30 when setting aws_conn2_t2_cgw_inside in infra/gcp/terraform.tfvars."
  value = length(module.vpn) > 0 ? module.vpn[0].conn2_t2_cgw_inside_address : ""
}
output "vpn_conn2_t2_vgw_inside_address" {
  value = length(module.vpn) > 0 ? module.vpn[0].conn2_t2_vgw_inside_address : ""
}

output "vpn_transit_gateway_id" {
  description = "Transit Gateway ID — reference for additional VPC or Direct Connect attachments."
  value = length(module.vpn) > 0 ? module.vpn[0].transit_gateway_id : ""
}
