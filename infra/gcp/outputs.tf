# ─── CLUSTERS ────────────────────────────────────────────────────────────────
output "gke_hub_name" {
  description = "Name of the GKE management cluster (hub)."
  value       = module.gke_hub.cluster_name
}

output "gke_spoke_name" {
  description = "Name of the GKE workload cluster (spoke)."
  value       = module.gke_spoke.cluster_name
}

output "gke_hub_endpoint" {
  description = "API endpoint of the GKE hub cluster."
  value       = module.gke_hub.cluster_endpoint
  sensitive   = true
}

output "gke_spoke_endpoint" {
  description = "API endpoint of the GKE spoke cluster."
  value       = module.gke_spoke.cluster_endpoint
  sensitive   = true
}

# ─── NETWORKING ───────────────────────────────────────────────────────────────
output "control_vpc_id" {
  description = "Self-link of the control-plane VPC."
  value       = module.vpc_control.vpc_id
}

output "lb_global_ip" {
  description = "Global static IP of the HTTPS load balancer. Create an A record pointing your domain here."
  value       = module.lb.global_ip
}

# ─── IDENTITY / CI/CD ────────────────────────────────────────────────────────
output "ci_service_account" {
  description = "Email of the CI/CD Service Account (used by GitHub Actions via WIF)."
  value       = module.identity.service_account_email
}

output "workload_identity_provider" {
  description = "Full WIF provider resource name — paste this into your GitHub Actions workflow as workload_identity_provider."
  value       = "projects/${var.control_plane_project_number}/locations/global/workloadIdentityPools/${var.env_name}-pool/providers/github-provider"
}

# ─── KMS (needed for Cloud Build image signing) ───────────────────────────────
output "cosign_key_id" {
  description = "Full resource ID of the Cosign KMS key — used in cloudbuild.yaml for image signing."
  value       = module.kms.cosign_key_id
}

output "gke_secret_key_id" {
  description = "Full resource ID of the GKE secret-encryption KMS key."
  value       = module.kms.gke_secret_key_id
}
