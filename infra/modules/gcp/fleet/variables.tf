variable "project_id" { description = "GCP Project ID" }

variable "clusters" {
  description = "Map of clusters to register in the fleet."
  type = map(object({
    id = string
  }))
}

variable "config_sync_repo" {
  description = "HTTPS URL of the Git repo Config Sync will sync from."
  type        = string
}

variable "config_sync_branch" {
  description = "Branch Config Sync tracks."
  type        = string
  default     = "main"
}

variable "eks_membership_name" {
  description = "Fleet membership name of the EKS cluster (registered via gcloud, not Terraform). Empty string disables the EKS feature membership."
  type        = string
  default     = ""
}
