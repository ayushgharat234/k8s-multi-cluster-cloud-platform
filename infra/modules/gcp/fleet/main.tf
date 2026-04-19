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
      resource_link = "//container.googleapis.com/projects/${split("/", each.value.id)[0]}/locations/${split("/", each.value.id)[1]}/clusters/${split("/", each.value.id)[2]}"
    }
  }
}

# 2. Enable Fleet Features (Managed Services)

resource "google_gke_hub_feature" "servicemesh" {
  name     = "servicemesh"
  location = "global"
  project  = var.project_id
}

# Bind managed ASM to each GKE cluster
resource "google_gke_hub_feature_membership" "service_mesh_gke" {
  for_each   = var.clusters
  project    = var.project_id
  location   = "global"
  feature    = google_gke_hub_feature.servicemesh.name
  membership = google_gke_hub_membership.gke_members[each.key].membership_id

  mesh {
    management = "MANAGEMENT_AUTOMATIC"
  }

  depends_on = [google_gke_hub_feature.servicemesh]
}

resource "google_gke_hub_feature" "configmanagement" {
  name     = "configmanagement"
  location = "global"
  project  = var.project_id
}

resource "google_gke_hub_feature" "policycontroller" {
  name     = "policycontroller"
  location = "global"
  project  = var.project_id

  # Fleet-level defaults — equivalent to "Configure fleet settings" in the UI.
  # Every new cluster joining the fleet inherits this automatically.
  fleet_default_member_config {
    policycontroller {
      policy_controller_hub_config {
        install_spec              = "INSTALL_SPEC_ENABLED"
        audit_interval_seconds    = 60
        referential_rules_enabled = true

        policy_content {
          template_library {
            installation = "ALL"
          }
          # Policy Essentials bundle: CIS K8s Benchmark, Pod Security Standards,
          # general best-practice guardrails — matches what the UI "Configure fleet settings" applies
          bundles {
            bundle = "policy-essentials-v2022"
            exempted_namespaces = [
              "kube-system",
              "gke-connect",
              "config-management-system",
              "config-management-monitoring",
              "gatekeeper-system",
              "resource-group-system",
              "asm-system",
              "istio-system",
            ]
          }
        }
      }
    }
  }
}

# 3. Config Sync per cluster (configmanagement feature)

resource "google_gke_hub_feature_membership" "config_sync_gke" {
  for_each   = var.clusters
  project    = var.project_id
  location   = "global"
  feature    = google_gke_hub_feature.configmanagement.name
  membership = google_gke_hub_membership.gke_members[each.key].membership_id

  configmanagement {
    version = "1.23.3"

    config_sync {
      enabled = true
      git {
        sync_repo   = var.config_sync_repo
        sync_branch = var.config_sync_branch
        policy_dir  = "platform/config-sync"
        secret_type = "none"
      }
      source_format = "hierarchy"
    }
  }

  depends_on = [google_gke_hub_feature.configmanagement]
}

resource "google_gke_hub_feature_membership" "config_sync_eks" {
  count      = var.eks_membership_name != "" ? 1 : 0
  project    = var.project_id
  location   = "global"
  feature    = google_gke_hub_feature.configmanagement.name
  membership = var.eks_membership_name

  configmanagement {
    version = "1.23.3"

    config_sync {
      enabled = true
      git {
        sync_repo   = var.config_sync_repo
        sync_branch = var.config_sync_branch
        policy_dir  = "platform/config-sync"
        secret_type = "none"
      }
      source_format = "hierarchy"
    }
  }

  depends_on = [google_gke_hub_feature.configmanagement]
}

# 4. Policy Controller per cluster (separate policycontroller feature — required for ACM >= 1.21)

resource "google_gke_hub_feature_membership" "policy_controller_gke" {
  for_each   = var.clusters
  project    = var.project_id
  location   = "global"
  feature    = google_gke_hub_feature.policycontroller.name
  membership = google_gke_hub_membership.gke_members[each.key].membership_id

  policycontroller {
    policy_controller_hub_config {
      install_spec = "INSTALL_SPEC_ENABLED"
      referential_rules_enabled = true
      policy_content {
        template_library {
          installation = "ALL"
        }
      }
      audit_interval_seconds = 60
    }
  }

  depends_on = [google_gke_hub_feature.policycontroller]
}

resource "google_gke_hub_feature_membership" "policy_controller_eks" {
  count      = var.eks_membership_name != "" ? 1 : 0
  project    = var.project_id
  location   = "global"
  feature    = google_gke_hub_feature.policycontroller.name
  membership = var.eks_membership_name

  policycontroller {
    policy_controller_hub_config {
      install_spec = "INSTALL_SPEC_ENABLED"
      referential_rules_enabled = true
      policy_content {
        template_library {
          installation = "ALL"
        }
      }
      audit_interval_seconds = 60
    }
  }

  depends_on = [google_gke_hub_feature.policycontroller]
}
