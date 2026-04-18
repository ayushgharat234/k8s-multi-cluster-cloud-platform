terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# 1. GCP Service Account for the Connect Agent running on EKS
resource "google_service_account" "connect_sa" {
  account_id   = "${var.env_name}-connect-sa"
  display_name = "Connect Agent SA for AWS EKS"
  project      = var.project_id
}

# 2. Grant Connect Agent SA the minimum role needed for hub membership management
resource "google_project_iam_member" "connect_sa_binding" {
  project = var.project_id
  role    = "roles/gkehub.connect"
  member  = "serviceAccount:${google_service_account.connect_sa.email}"
}

# NOTE: EKS Fleet registration is done via gcloud CLI (not Terraform) because
# google_container_attached_cluster requires GCP to reach the EKS API server
# during apply, which is not reliable. Instead, run:
#   gcloud container fleet memberships register opsnexus-eks-spoke \
#     --context=arn:aws:eks:us-east-1:ACCOUNT:cluster/opsnexus-eks-spoke \
#     --enable-workload-identity --project=PROJECT_ID
