output "service_account_email" {
  description = "The email of the CI/CD Service Account."
  value       = google_service_account.ci_sa.email
}

output "workload_identity_pool_id" {
  description = "The ID of the Workload Identity Pool."
  value       = google_iam_workload_identity_pool.pool.workload_identity_pool_id
}

output "workload_identity_provider_id" {
  description = "The ID of the Workload Identity Provider."
  value       = google_iam_workload_identity_pool_provider.github.workload_identity_pool_provider_id
}

output "wait_finished" {
  description = "A dummy output that only resolves after the IAM wait period is finished."
  value       = time_sleep.wait_for_iam.id
}
