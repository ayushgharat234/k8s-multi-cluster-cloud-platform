variable "project_id" {}
variable "region" {}
variable "cluster_name" {}
variable "network_self_link" {}
variable "subnet_self_link" {}
variable "pods_secondary_range_name" {}
variable "services_secondary_range_name" {}
variable "machine_type" { default = "e2-standard-4" }
variable "node_count" { default = 1 }