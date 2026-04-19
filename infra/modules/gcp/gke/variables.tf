variable "project_id" {
  description = "The GCP Project ID."
  type        = string
}

variable "fleet_project_id" {
  description = "Fleet host project ID for Workload Identity pool. Defaults to project_id for single-project setups."
  type        = string
  default     = ""
}

variable "project_number" {
  description = "The GCP Project Number (for service agent IAM bindings)."
  type        = string
}

variable "region" {
  description = "The GCP region."
  type        = string
}

variable "env_name" {
  description = "Environment name suffix."
  type        = string
}

variable "vpc_id" {
  description = "The VPC network ID."
  type        = string
}

variable "subnet_id" {
  description = "The VPC subnetwork ID."
  type        = string
}

variable "pod_range_name" {
  description = "The name of the secondary range for pods."
  type        = string
}

variable "service_range_name" {
  description = "The name of the secondary range for services."
  type        = string
}

variable "kms_secret_key_id" {
  description = "KMS Key ID for GKE application-layer secret encryption."
  type        = string
}

variable "kms_disk_key_id" {
  description = "KMS Key ID for GKE node boot disk encryption."
  type        = string
}

variable "kms_cosign_key_id" {
  description = "KMS Key ID for Cosign image signing (Binary Authorization)."
  type        = string
}

variable "kms_cosign_public_key_pem" {
  description = "Public key PEM for the Cosign key."
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the GKE master (control plane)."
  type        = string
}

variable "master_authorized_cidr_blocks" {
  description = "List of CIDR blocks allowed to reach the GKE API server."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "node_count" {
  description = "Initial number of nodes per zone."
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "Machine type for the nodes."
  type        = string
  default     = "e2-standard-2"
}

variable "hub_attestor_resource_name" {
  description = "Full resource name of the hub attestor for cross-project BinAuth (spoke clusters only). Empty = use local attestor."
  type        = string
  default     = ""
}
