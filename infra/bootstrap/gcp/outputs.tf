output "gcp_state_bucket" {
  description = "The name of the GCS bucket for Terraform state"
  value       = google_storage_bucket.state.name
}

output "gcp_hsm_key" {
  description = "The HMS-backed KMS key for state encryption"
  value       = google_kms_crypto_key.state_key.id
}
