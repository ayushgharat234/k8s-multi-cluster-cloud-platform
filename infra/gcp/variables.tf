variable "control_plane_project_id" {
  description = "GCP Project ID for the control plane (hub cluster, KMS, identity)."
  type        = string
}

variable "control_plane_project_number" {
  description = "GCP Project Number for the control plane."
  type        = string
}

variable "data_plane_project_id" {
  description = "GCP Project ID for the data plane (spoke cluster)."
  type        = string
}

variable "data_plane_project_number" {
  description = "GCP Project Number for the data plane."
  type        = string
}

variable "region" {
  description = "The GCP region for all resources."
  type        = string
  default     = "us-central1"
}

variable "env_name" {
  description = "Short environment name prefix (e.g. opsnexus)."
  type        = string
  default     = "opsnexus"
}

variable "github_repo" {
  description = "GitHub repository in 'owner/repo' format for Workload Identity Federation."
  type        = string
}

variable "domain" {
  description = "Fully-qualified domain name for the global HTTPS load balancer certificate."
  type        = string
}

variable "master_authorized_cidr_blocks" {
  description = "CIDR blocks allowed to reach the GKE API servers (e.g. VPN or bastion IP)."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

# --- Multi-cloud fleet integration ---

variable "eks_oidc_url" {
  description = "EKS OIDC issuer URL for Fleet Attached Cluster registration. Obtained from: cd infra/aws && terraform output oidc_provider_url"
  type        = string
  default     = ""
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster to register in the GCP Fleet."
  type        = string
  default     = "opsnexus-eks-spoke"
}

# Legacy subnet/pod/service CIDR variables kept for backwards compatibility
variable "subnet_cidr"  { default = "10.0.0.0/20" }
variable "pod_cidr"     { default = "10.1.0.0/16" }
variable "service_cidr" { default = "10.2.0.0/20" }
