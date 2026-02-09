variable "project_id" {
  description = "The Host Project ID (Networking)"
  type        = string
}

variable "management_project_id" {
  description = "The Service Project ID for the Management Cluster"
  type        = string
}

variable "tenant_1_project_id" {
  description = "The Service Project ID for Tenant Cluster 1"
  type        = string
}

variable "tenant_2_project_id" {
  description = "The Service Project ID for Tenant Cluster 2"
  type        = string
}

variable "region" {}
variable "subnet_cidr" {}
variable "pods_cidr" {}
variable "services_cidr" {}

variable "service_project_ids" {
  type    = list(string)
  default = []
}

variable "service_project_numbers" {
  type    = list(string)
  default = []
}