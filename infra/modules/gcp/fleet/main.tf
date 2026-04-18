terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# 1. Register GKE Clusters to the Fleet
resource "google_gke_hub_membership" "gke_members" {
  for_each      = var.clusters
  membership_id = each.key
  project       = var.project_id

  endpoint {
    gke_cluster {
      # Expected format of each.value.id: "project_id/location/cluster_name"
      resource_link = "//container.googleapis.com/projects/${split("/", each.value.id)[0]}/locations/${split("/", each.value.id)[1]}/clusters/${split("/", each.value.id)[2]}"
    }
  }
}

# 2. Enable Fleet Features (Managed Services)

# Managed Service Mesh (ASM)
resource "google_gke_hub_feature" "servicemesh" {
  name     = "servicemesh"
  location = "global"
  project  = var.project_id
}

# Config Management (GitOps)
resource "google_gke_hub_feature" "configmanagement" {
  name     = "configmanagement"
  location = "global"
  project  = var.project_id
}

# Policy Controller (Governance)
resource "google_gke_hub_feature" "policycontroller" {
  name     = "policycontroller"
  location = "global"
  project  = var.project_id
}
