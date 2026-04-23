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

variable "gcp_ci_sa_unique_id" {
  description = "Unique numeric ID of the GCP CI service account (opsnexus-ci-sa). Used in the AWS IAM trust policy for Workload Identity Federation. Get with: gcloud iam service-accounts describe opsnexus-ci-sa@PROJECT.iam.gserviceaccount.com --format='value(uniqueId)'"
  type        = string
}

# ── Site-to-Site VPN — GCP HA VPN Gateway IPs ─────────────────────────────────
# Obtained after Phase 1 (terraform apply -target="module.vpn_data" in infra/gcp):
#   gcp_vpn_interface_0_ip = terraform -chdir=infra/gcp output gcp_vpn_gateway_ip
#   gcp_vpn_interface_1_ip = terraform -chdir=infra/gcp output gcp_vpn_gateway_ip_1
variable "gcp_vpn_interface_0_ip" {
  description = "External IP of GCP HA VPN Gateway interface 0. Used as Customer Gateway 1."
  type        = string
  default     = ""
}
variable "gcp_vpn_interface_1_ip" {
  description = "External IP of GCP HA VPN Gateway interface 1. Used as Customer Gateway 2."
  type        = string
  default     = ""
}

# ── Pre-defined PSKs (4 tunnels = 4 PSKs) ─────────────────────────────────────
# Choose strong secrets (8-64 ASCII chars) BEFORE applying.
# Paste the SAME values into infra/gcp/terraform.tfvars under aws_conn*_t*_psk.
# Store secrets out of git (use .env + TF_VAR_* or a secrets manager).
variable "vpn_conn1_t1_psk" {
  description = "PSK for connection 1, tunnel 1. Same as aws_conn1_t1_psk in infra/gcp."
  type        = string
  sensitive   = true
  default     = ""
}
variable "vpn_conn1_t2_psk" {
  description = "PSK for connection 1, tunnel 2. Same as aws_conn1_t2_psk in infra/gcp."
  type        = string
  sensitive   = true
  default     = ""
}
variable "vpn_conn2_t1_psk" {
  description = "PSK for connection 2, tunnel 1. Same as aws_conn2_t1_psk in infra/gcp."
  type        = string
  sensitive   = true
  default     = ""
}
variable "vpn_conn2_t2_psk" {
  description = "PSK for connection 2, tunnel 2. Same as aws_conn2_t2_psk in infra/gcp."
  type        = string
  sensitive   = true
  default     = ""
}
