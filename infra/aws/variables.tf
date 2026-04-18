variable "region" {
  description = "The AWS region."
  type        = string
  default     = "us-east-1"
}

variable "env_name" {
  description = "Environment name."
  type        = string
  default     = "opsnexus"
}

variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
  default     = "opsnexus-eks-spoke"
}

variable "vpc_cidr" {
  description = "CIDR for the AWS VPC."
  type        = string
  default     = "172.16.0.0/16"
}

variable "github_repo" {
  description = "GitHub repository (owner/repo) for OIDC trust."
  type        = string
}

variable "github_thumbprint" {
  description = "Thumbprint for the GitHub OIDC provider."
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "eks_allowed_cidrs" {
  description = "CIDRs allowed to reach the EKS public API endpoint. Set to your IP/32."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
