output "gke_disk_key_id" {
  description = "The ID of the GKE disk encryption key."
  value       = google_kms_crypto_key.gke_disk_key.id
}

output "gke_secret_key_id" {
  description = "The ID of the GKE secret encryption key."
  value       = google_kms_crypto_key.gke_secret_key.id
}

output "cosign_key_id" {
  description = "The ID of the Cosign asymmetric signing key."
  value       = google_kms_crypto_key.cosign_key.id
}

output "cosign_public_key_pem" {
  description = "The public key PEM for the Cosign key."
  value       = data.google_kms_crypto_key_version.cosign_version.public_key[0].pem
}

data "google_kms_crypto_key_version" "cosign_version" {
  crypto_key = google_kms_crypto_key.cosign_key.id
}
