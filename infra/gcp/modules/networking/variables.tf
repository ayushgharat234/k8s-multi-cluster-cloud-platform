variable "project_id" {
  description = "The ID of the project where the VPC will be created"
  type        = string
}

variable "region" {
  description = "The region for subnets and Cloud NAT"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the GKE subnet"
  type        = string
}

variable "subnet_cidr" {
  description = "The primary CIDR range for the subnet (Nodes)"
  type        = string
}

variable "pods_cidr" {
  description = "The secondary CIDR range for Pods"
  type        = string
}

variable "services_cidr" {
  description = "The secondary CIDR range for Services"
  type        = string
}
