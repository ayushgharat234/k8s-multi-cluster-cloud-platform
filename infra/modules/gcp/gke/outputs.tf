output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "ca_certificate" {
  value     = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive = true
}

output "workload_identity_pool" {
  value = google_container_cluster.primary.workload_identity_config[0].workload_pool
}

output "node_sa_email" {
  value = google_service_account.node_sa.email
}
