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

# 3. Per-cluster feature configuration

# Config Sync + Policy Controller: GKE Hub and GKE Spoke
# (clusters registered via Terraform — membership resource exists in this module)
resource "google_gke_hub_feature_membership" "config_sync_gke" {
  for_each   = var.clusters
  project    = var.project_id
  location   = "global"
  feature    = google_gke_hub_feature.configmanagement.name
  membership = google_gke_hub_membership.gke_members[each.key].membership_id

  configmanagement {
    version = "1.19"

    config_sync {
      git {
        sync_repo   = var.config_sync_repo
        sync_branch = var.config_sync_branch
        policy_dir  = "platform/config-sync"
        secret_type = "none"
      }
      source_format = "hierarchy"
    }

    policy_controller {
      enabled                    = true
      template_library_installed = true
      referential_rules_enabled  = true
      audit_interval_seconds     = "60"
    }
  }

  depends_on = [
    google_gke_hub_feature.configmanagement,
    google_gke_hub_feature.policycontroller,
  ]
}

# Config Sync + Policy Controller: EKS Spoke (opsnexus-eks-spoke)
# Registered via gcloud CLI (not Terraform) — membership name is fixed/known.
# Only created when var.eks_membership_name is set (after EKS registration).
resource "google_gke_hub_feature_membership" "config_sync_eks" {
  count      = var.eks_membership_name != "" ? 1 : 0
  project    = var.project_id
  location   = "global"
  feature    = google_gke_hub_feature.configmanagement.name
  membership = var.eks_membership_name

  configmanagement {
    version = "1.19"

    config_sync {
      git {
        sync_repo   = var.config_sync_repo
        sync_branch = var.config_sync_branch
        policy_dir  = "platform/config-sync"
        secret_type = "none"
      }
      source_format = "hierarchy"
    }

    policy_controller {
      enabled                    = true
      template_library_installed = true
      referential_rules_enabled  = true
      audit_interval_seconds     = "60"
    }
  }

  depends_on = [
    google_gke_hub_feature.configmanagement,
    google_gke_hub_feature.policycontroller,
  ]
}
