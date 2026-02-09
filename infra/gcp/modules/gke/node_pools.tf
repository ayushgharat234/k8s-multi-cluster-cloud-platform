resource "google_service_account" "node_sa" {
  account_id   = "${var.cluster_name}-node-sa"
  display_name = "GKE Node Service Account"
  project      = var.project_id
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-pool-01"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    
    # Google Recommended Security
    service_account = google_service_account.node_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot = true
    }
  }
}