resource "random_id" "suffix" {
  byte_length = 4
}

# 1. GCS Bucket for Terraform State
resource "google_storage_bucket" "state" {
  name                        = "opsnexus-tfstate-${random_id.suffix.hex}"
  location                    = var.gcp_region
  force_destroy               = false
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.state_key.id
  }

  depends_on = [google_kms_crypto_key_iam_member.storage_signer]
}

# 2. Cloud KMS Key Ring for the Pillar
resource "google_kms_key_ring" "state_ring" {
  name     = "opsnexus-state-ring"
  location = var.gcp_region
}

# 3. HSM-backed Crypto Key for encryption
resource "google_kms_crypto_key" "state_key" {
  name            = "opsnexus-state-key-v2"
  key_ring        = google_kms_key_ring.state_ring.id
  purpose         = "ENCRYPT_DECRYPT"
  
  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"
  }
}

# 4. RBAC: Allow Cloud Storage Service Agent to use the key
resource "google_kms_crypto_key_iam_member" "storage_signer" {
  crypto_key_id = google_kms_crypto_key.state_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.gcp_project_number}@gs-project-accounts.iam.gserviceaccount.com"
}
