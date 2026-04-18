variable "cluster_name"    { description = "Name of the EKS cluster" }
variable "env_name"        { description = "Environment name" }
variable "vpc_id"          { description = "VPC ID for the cluster security group" }
variable "cluster_role_arn" { description = "IAM role for the EKS control plane" }
variable "node_role_arn"    { description = "IAM role for the EKS nodes" }
variable "subnet_ids"       { description = "List of private subnet IDs" }
variable "kms_key_arn"      { description = "KMS Key for secret encryption" }
variable "ebs_kms_key_arn"  { description = "KMS Key for EBS encryption" }

variable "instance_type"    { default = "t3.medium" }
variable "desired_capacity" { default = 1 }
variable "max_capacity"     { default = 2 }
variable "min_capacity"     { default = 1 }
variable "volume_size"      { default = 20 }

variable "allowed_public_cidrs" {
  description = "CIDRs allowed to reach the EKS public API endpoint (your IP + GCP ranges)"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # overridden in infra/aws/main.tf
}
