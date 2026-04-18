variable "env_name" {
  description = "Environment name."
  type        = string
}

variable "project_id" {
  description = "The Control Plane Project ID."
  type        = string
}

variable "project_number" {
  description = "The Control Plane Project Number."
  type        = string
}

variable "data_plane_project_id" {
  description = "The Data Plane Project ID for cross-project RBAC."
  type        = string
}

variable "data_plane_project_number" {
  description = "The Data Plane Project Number."
  type        = string
}

variable "github_repo" {
  description = "The GitHub repository in 'owner/repo' format."
  type        = string
}
