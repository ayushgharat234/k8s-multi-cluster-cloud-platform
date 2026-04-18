variable "project_id" {
  description = "The GCP Project ID."
  type        = string
}

variable "region" {
  description = "The GCP region."
  type        = string
}

variable "env_name" {
  description = "The environment name (e.g. opsnexus)."
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR range for the primary subnet."
  type        = string
  default     = "10.0.0.0/20"
}

variable "pod_cidr" {
  description = "CIDR range for the GKE pods."
  type        = string
  default     = "10.1.0.0/16"
}

variable "service_cidr" {
  description = "CIDR range for the GKE services."
  type        = string
  default     = "10.2.0.0/20"
}

variable "peer_cidr_ranges" {
  description = "CIDR ranges from peered VPCs to allow in firewall."
  type        = list(string)
  default     = []
}

variable "master_cidr" {
  description = "CIDR of the GKE master (control plane) for targeted firewall rules."
  type        = string
  default     = "172.16.0.0/28"
}
