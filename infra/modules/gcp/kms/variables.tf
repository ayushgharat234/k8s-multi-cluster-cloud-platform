variable "project_id" {
  description = "The GCP Project ID."
  type        = string
}

variable "project_number" {
  description = "The Control Plane GCP Project Number."
  type        = string
}

variable "data_plane_project_number" {
  description = "The Data Plane GCP Project Number for cross-project GKE access."
  type        = string
  default     = ""
}

variable "region" {
  description = "The GCP region."
  type        = string
}

variable "env_name" {
  description = "The environment name (e.g. opsnexus)."
  type        = string
}
