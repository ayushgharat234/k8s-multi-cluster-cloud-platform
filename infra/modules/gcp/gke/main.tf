terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# --- DEDICATED NODE SERVICE ACCOUNT ---
# Separate from the CI/CD SA; minimal permissions following principle of least privilege
resource "google_service_account" "node_sa" {
  account_id   = "${var.env_name}-node-sa"
  display_name = "GKE Node Service Account for ${var.env_name}"
  project      = var.project_id
}

resource "google_project_iam_member" "node_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",         # Push node/system logs to Cloud Logging
    "roles/monitoring.metricWriter",   # Push metrics to Cloud Monitoring
    "roles/monitoring.viewer",         # Read monitoring data (for agents)
    "roles/storage.objectViewer",      # Pull container images from GCR
    "roles/artifactregistry.reader",   # Pull container images from Artifact Registry
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.node_sa.email}"
}

# Allow the GKE service agent to act as the node SA (required for node pool provisioning)
resource "google_service_account_iam_member" "gke_agent_node_sa" {
  service_account_id = google_service_account.node_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:service-${var.project_number}@container-engine-robot.iam.gserviceaccount.com"
}

# --- GKE CLUSTER ---
resource "google_container_cluster" "primary" {
  name     = "${var.env_name}-cluster"
  location = var.region
  project  = var.project_id

  network    = var.vpc_id
  subnetwork = var.subnet_id

  # Private cluster: nodes have no public IPs, control plane access via authorized networks
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # Set true when a Bastion/VPN is in place
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Restrict who can reach the control plane API
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_cidr_blocks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # eBPF-based dataplane — enables NetworkPolicy enforcement without kube-proxy
  datapath_provider = "ADVANCED_DATAPATH"

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR"
  }

  # Application-layer secret encryption with shared KMS key
  database_encryption {
    state    = "ENCRYPTED"
    key_name = var.kms_secret_key_id
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_range_name
    services_secondary_range_name = var.service_range_name
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  # Workaround: Google API returns "ALL_OBJECTS_ENCRYPTION_ENABLED" for
  # database_encryption.state but the provider only accepts "ENCRYPTED".
  # This is a known drift bug — ignore it to prevent perpetual 400 errors.
  deletion_protection = false

  lifecycle {
    ignore_changes = [
      database_encryption[0].state,
    ]
  }

  depends_on = [
    google_service_account_iam_member.gke_agent_node_sa,
    google_project_iam_member.node_sa_roles,
  ]
}

# --- NODE POOL ---
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.env_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  node_count = var.node_count

  node_config {
    # Use spot VMs (successor to preemptible) for cost efficiency on portfolio/demo
    spot         = true
    machine_type = var.machine_type

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Workload Identity: pods use k8s SA → GCP SA mapping, not the node SA
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Dedicated minimal node SA — not the CI/CD SA
    service_account = google_service_account.node_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    # CMEK boot disk encryption (handled by Compute Engine service agent)
    boot_disk_kms_key = var.kms_disk_key_id

    labels = { env = var.env_name }
    tags   = ["gke-node", var.env_name]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# --- BINARY AUTHORIZATION ---

# Container Analysis Note: stores attestation metadata
resource "google_container_analysis_note" "note" {
  name    = "${var.env_name}-attestation-note"
  project = var.project_id
  attestation_authority {
    hint {
      human_readable_name = "OpsNexus Attestation Note"
    }
  }
}

# Attestor: the signing authority backed by our KMS cosign key
resource "google_binary_authorization_attestor" "opsnexus_attestor" {
  name    = "${var.env_name}-attestor"
  project = var.project_id

  attestation_authority_note {
    note_reference = google_container_analysis_note.note.name
    public_keys {
      id = var.kms_cosign_key_id
      pkix_public_key {
        public_key_pem      = var.kms_cosign_public_key_pem
        signature_algorithm = "RSA_PSS_2048_SHA256"
      }
    }
  }
}

# Policy: block all images not attested by our attestor
resource "google_binary_authorization_policy" "policy" {
  project = var.project_id

  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [
      google_binary_authorization_attestor.opsnexus_attestor.name
    ]
  }

  # GKE system components — exempt from attestation requirement
  admission_whitelist_patterns {
    name_pattern = "registry.k8s.io/*"
  }
  admission_whitelist_patterns {
    name_pattern = "gke.gcr.io/*"
  }
  admission_whitelist_patterns {
    name_pattern = "gcr.io/google-containers/*"
  }
  admission_whitelist_patterns {
    name_pattern = "gcr.io/gke-release/*"
  }
}
