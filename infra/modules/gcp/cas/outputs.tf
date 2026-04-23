output "root_ca_pool_id" {
  description = "Full resource ID of the root CA pool."
  value       = google_privateca_ca_pool.root.id
}

output "root_ca_name" {
  description = "Full resource name of the root CA."
  value       = google_privateca_certificate_authority.root.name
}

output "subordinate_ca_pool_id" {
  description = "Full resource ID of the subordinate CA pool. Pass to workloads that request certs."
  value       = google_privateca_ca_pool.subordinate.id
}

output "mesh_ca_name" {
  description = "Full resource name of the Mesh mTLS subordinate CA."
  value       = google_privateca_certificate_authority.mesh.name
}

output "internal_tls_ca_name" {
  description = "Full resource name of the Internal TLS subordinate CA."
  value       = google_privateca_certificate_authority.internal_tls.name
}

output "workload_ca_name" {
  description = "Full resource name of the Workload Identity subordinate CA."
  value       = google_privateca_certificate_authority.workload.name
}

output "subordinate_ca_pool_name" {
  description = "Short name of the subordinate CA pool (for ASM custom CA configuration)."
  value       = google_privateca_ca_pool.subordinate.name
}
