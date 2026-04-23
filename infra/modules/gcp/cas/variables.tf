variable "project_id" {
  description = "The GCP project ID where CAS resources are created."
  type        = string
}

variable "region" {
  description = "The GCP region for CA pools and CAs."
  type        = string
}

variable "env_name" {
  description = "Environment name prefix for all resources (e.g. opsnexus)."
  type        = string
}

variable "organization" {
  description = "Organization name embedded in CA subject fields (e.g. OpsNexus)."
  type        = string
  default     = "OpsNexus"
}

variable "ci_service_account_email" {
  description = "Email of the CI service account granted certificateRequester on the subordinate pool."
  type        = string
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of CAs. Set false for demo/dev environments."
  type        = bool
  default     = false
}
