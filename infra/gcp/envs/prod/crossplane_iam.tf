# Issue #14: Crossplane Identity Binding
# This grants the "Management Cluster" permission to manage GCP resources.

# 1. Create a Google Service Account (GSA) for Crossplane
resource "google_service_account" "crossplane_sa" {
  account_id   = "crossplane-provider"
  display_name = "Crossplane Provider GCP Service Account"
  project      = var.management_project_id
}

# 2. Grant "Editor" (or specific Application Roles) to this GSA
# In a real prod, rely on specific roles. For bootstrap, Editor is common for the Platform Admin.
resource "google_project_iam_member" "crossplane_editor" {
  project = var.management_project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.crossplane_sa.email}"
}

# Also grant Network Admin on the Host Project so it can peek at the VPC
resource "google_project_iam_member" "crossplane_network_admin" {
  project = var.project_id # Host Project
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.crossplane_sa.email}"
}

# 3. Bind the GSA to the Kubernetes Service Account (KSA)
# Note: The KSA is creating by the Crossplane Helm Chart.
# Namespace: crossplane-system
# Name: provider-gcp-* (matches the deployment)
resource "google_service_account_iam_member" "crossplane_workload_identity" {
  service_account_id = google_service_account.crossplane_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.management_project_id}.svc.id.goog[crossplane-system/provider-gcp-default]"
}

# Output the GSA Email so we can use it in "provider-config.yaml" if needed (though we hardcoded 'InjectedIdentity')
output "crossplane_sa_email" {
  value = google_service_account.crossplane_sa.email
}
