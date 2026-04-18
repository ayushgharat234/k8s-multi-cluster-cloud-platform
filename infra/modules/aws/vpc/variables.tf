variable "env_name" {
  description = "Environment name."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR for the AWS VPC."
  type        = string
  default     = "172.16.0.0/16"
}

variable "cluster_name" {
  description = "Name of the EKS cluster for tagging."
  type        = string
}
