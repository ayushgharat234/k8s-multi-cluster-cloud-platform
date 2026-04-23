variable "control_plane_project_id" {
  description = "GCP Project ID for the control plane (hub cluster, KMS, identity)."
  type        = string
}

variable "control_plane_project_number" {
  description = "GCP Project Number for the control plane."
  type        = string
}

variable "data_plane_project_id" {
  description = "GCP Project ID for the data plane (spoke cluster)."
  type        = string
}

variable "data_plane_project_number" {
  description = "GCP Project Number for the data plane."
  type        = string
}

variable "region" {
  description = "The GCP region for all resources."
  type        = string
  default     = "us-central1"
}

variable "env_name" {
  description = "Short environment name prefix (e.g. opsnexus)."
  type        = string
  default     = "opsnexus"
}

variable "github_repo" {
  description = "GitHub repository in 'owner/repo' format for Workload Identity Federation."
  type        = string
}

variable "domain" {
  description = "Fully-qualified domain name for the global HTTPS load balancer certificate. Empty = HTTP-only."
  type        = string
  default     = ""
}

variable "dns_zone_dns_name" {
  description = "Cloud DNS zone dns_name (e.g. 'example.com.'). Empty = skip DNS zone creation."
  type        = string
  default     = ""
}

variable "frontend_neg_ids" {
  description = "NEG self-links for the frontend service. Populated after first workload deploy."
  type        = list(string)
  default     = []
}

variable "payment_neg_ids" {
  description = "NEG self-links for the payment service. Populated after first workload deploy."
  type        = list(string)
  default     = []
}

variable "iap_client_id" {
  description = "OAuth 2.0 client ID for IAP on the frontend. Empty = IAP disabled."
  type        = string
  default     = ""
}

variable "iap_client_secret" {
  description = "OAuth 2.0 client secret for IAP."
  type        = string
  default     = ""
  sensitive   = true
}

variable "iap_members" {
  description = "IAM members granted IAP access (e.g. ['user:you@example.com', 'group:team@example.com'])."
  type        = list(string)
  default     = []
}

variable "organization" {
  description = "Organization name embedded in CA subject fields."
  type        = string
  default     = "OpsNexus"
}

variable "master_authorized_cidr_blocks" {
  description = "CIDR blocks allowed to reach the GKE API servers (e.g. VPN or bastion IP)."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

# --- Config Sync ---

variable "config_sync_repo" {
  description = "HTTPS URL of the Git repo Config Sync will sync platform/ from."
  type        = string
  default     = "https://github.com/ayushgharat234/k8s-multi-cluster-cloud-platform"
}

variable "config_sync_branch" {
  description = "Branch Config Sync tracks."
  type        = string
  default     = "main"
}

# --- Multi-cloud fleet integration ---

variable "eks_oidc_url" {
  description = "EKS OIDC issuer URL for Fleet Attached Cluster registration. Obtained from: cd infra/aws && terraform output oidc_provider_url"
  type        = string
  default     = ""
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster to register in the GCP Fleet."
  type        = string
  default     = "opsnexus-eks-spoke"
}

variable "eks_membership_name" {
  description = "Fleet membership name of the EKS cluster (set after gcloud fleet registration). Empty disables EKS Config Sync + Policy Controller feature membership."
  type        = string
  default     = "opsnexus-eks-spoke"
}

# Legacy subnet/pod/service CIDR variables kept for backwards compatibility
variable "subnet_cidr"  { default = "10.0.0.0/20" }
variable "pod_cidr"     { default = "10.1.0.0/16" }
variable "service_cidr" { default = "10.2.0.0/20" }

# ─── AWS VPN tunnel values (phase 3 — fill from infra/aws terraform output after phase 2) ───
# Connection 1 (TGW ↔ CGW1 / GCP interface 0) — GCP tunnels 1 & 2
variable "aws_conn1_t1_outside_ip" {
  description = "AWS outside IP for conn1/tunnel1 (terraform output vpn_conn1_t1_outside_ip)."
  type        = string
  default     = ""
}
variable "aws_conn1_t1_psk" {
  description = "PSK for conn1/tunnel1. Same value as vpn_conn1_t1_psk in infra/aws/terraform.tfvars."
  type        = string
  default     = ""
  sensitive   = true
}
variable "aws_conn1_t1_cgw_inside" {
  description = "GCP BGP IP /30 for conn1/tunnel1 (terraform output vpn_conn1_t1_cgw_inside_address + '/30')."
  type        = string
  default     = ""
}
variable "aws_conn1_t1_vgw_inside" {
  description = "TGW BGP peer IP for conn1/tunnel1 (terraform output vpn_conn1_t1_vgw_inside_address)."
  type        = string
  default     = ""
}

variable "aws_conn1_t2_outside_ip" {
  description = "AWS outside IP for conn1/tunnel2 (terraform output vpn_conn1_t2_outside_ip)."
  type        = string
  default     = ""
}
variable "aws_conn1_t2_psk" {
  description = "PSK for conn1/tunnel2. Same value as vpn_conn1_t2_psk in infra/aws/terraform.tfvars."
  type        = string
  default     = ""
  sensitive   = true
}
variable "aws_conn1_t2_cgw_inside" {
  description = "GCP BGP IP /30 for conn1/tunnel2 (terraform output vpn_conn1_t2_cgw_inside_address + '/30')."
  type        = string
  default     = ""
}
variable "aws_conn1_t2_vgw_inside" {
  description = "TGW BGP peer IP for conn1/tunnel2 (terraform output vpn_conn1_t2_vgw_inside_address)."
  type        = string
  default     = ""
}

# Connection 2 (TGW ↔ CGW2 / GCP interface 1) — GCP tunnels 3 & 4
variable "aws_conn2_t1_outside_ip" {
  description = "AWS outside IP for conn2/tunnel1 (terraform output vpn_conn2_t1_outside_ip)."
  type        = string
  default     = ""
}
variable "aws_conn2_t1_psk" {
  description = "PSK for conn2/tunnel1. Same value as vpn_conn2_t1_psk in infra/aws/terraform.tfvars."
  type        = string
  default     = ""
  sensitive   = true
}
variable "aws_conn2_t1_cgw_inside" {
  description = "GCP BGP IP /30 for conn2/tunnel1 (terraform output vpn_conn2_t1_cgw_inside_address + '/30')."
  type        = string
  default     = ""
}
variable "aws_conn2_t1_vgw_inside" {
  description = "TGW BGP peer IP for conn2/tunnel1 (terraform output vpn_conn2_t1_vgw_inside_address)."
  type        = string
  default     = ""
}

variable "aws_conn2_t2_outside_ip" {
  description = "AWS outside IP for conn2/tunnel2 (terraform output vpn_conn2_t2_outside_ip)."
  type        = string
  default     = ""
}
variable "aws_conn2_t2_psk" {
  description = "PSK for conn2/tunnel2. Same value as vpn_conn2_t2_psk in infra/aws/terraform.tfvars."
  type        = string
  default     = ""
  sensitive   = true
}
variable "aws_conn2_t2_cgw_inside" {
  description = "GCP BGP IP /30 for conn2/tunnel2 (terraform output vpn_conn2_t2_cgw_inside_address + '/30')."
  type        = string
  default     = ""
}
variable "aws_conn2_t2_vgw_inside" {
  description = "TGW BGP peer IP for conn2/tunnel2 (terraform output vpn_conn2_t2_vgw_inside_address)."
  type        = string
  default     = ""
}
