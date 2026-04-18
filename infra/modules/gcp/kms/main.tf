terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Key Ring for the Cluster/Regional Resources
resource "google_kms_key_ring" "cluster_ring" {
  name     = "${var.env_name}-cluster-ring"
  location = var.region
  project  = var.project_id
}

# Key for GKE Boot Disk Encryption (CMEK via Compute Engine service agent)
resource "google_kms_crypto_key" "gke_disk_key" {
  name     = "gke-disk-key"
  key_ring = google_kms_key_ring.cluster_ring.id
  purpose  = "ENCRYPT_DECRYPT"

  rotation_period = "7776000s" # 90 days

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"
  }
}

# Key for GKE Secret Encryption (application-layer, via GKE service agent)
resource "google_kms_crypto_key" "gke_secret_key" {
  name     = "gke-secret-key"
  key_ring = google_kms_key_ring.cluster_ring.id
  purpose  = "ENCRYPT_DECRYPT"

  rotation_period = "7776000s" # 90 days

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"
  }
}

# --- DISK KEY IAM ---
# Boot-disk CMEK uses the Compute Engine service agent, NOT the GKE service agent.
# Grant to the control project's Compute Engine service agent
resource "google_kms_crypto_key_iam_member" "compute_disk_encrypter" {
  crypto_key_id = google_kms_crypto_key.gke_disk_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.project_number}@compute-system.iam.gserviceaccount.com"
}

# Cross-project: Grant to the data project's Compute Engine service agent (spoke nodes)
resource "google_kms_crypto_key_iam_member" "compute_data_disk_encrypter" {
  count         = var.data_plane_project_number != "" ? 1 : 0
  crypto_key_id = google_kms_crypto_key.gke_disk_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.data_plane_project_number}@compute-system.iam.gserviceaccount.com"
}

# --- SECRET KEY IAM ---
# Application-layer secret encryption uses the GKE service agent (container-engine-robot)
resource "google_kms_crypto_key_iam_member" "gke_secret_encrypter" {
  crypto_key_id = google_kms_crypto_key.gke_secret_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.project_number}@container-engine-robot.iam.gserviceaccount.com"
}

# Cross-project: Data project's GKE service agent on secret key (shared KMS)
resource "google_kms_crypto_key_iam_member" "gke_data_secret_encrypter" {
  count         = var.data_plane_project_number != "" ? 1 : 0
  crypto_key_id = google_kms_crypto_key.gke_secret_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.data_plane_project_number}@container-engine-robot.iam.gserviceaccount.com"
}

# Key for Cosign Image Signing (asymmetric RSA)
resource "google_kms_crypto_key" "cosign_key" {
  name     = "cosign-key"
  key_ring = google_kms_key_ring.cluster_ring.id
  purpose  = "ASYMMETRIC_SIGN"

  version_template {
    algorithm        = "RSA_SIGN_PSS_2048_SHA256"
    protection_level = "HSM"
  }

  # Asymmetric keys do not support automatic rotation; versions are created manually
  lifecycle {
    prevent_destroy = false
  }
}

# Allow Cloud Build to sign images using the cosign key
resource "google_kms_crypto_key_iam_member" "cloudbuild_signer" {
  crypto_key_id = google_kms_crypto_key.cosign_key.id
  role          = "roles/cloudkms.signerVerifier"
  member        = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}
