variable "env_name"                  { type = string }
variable "vpc_id"                     { type = string }
variable "cluster_security_group_id"  { type = string }

# GCP HA VPN has 2 interfaces — create one CGW per interface for full 4-tunnel HA
variable "gcp_vpn_interface_0_ip" {
  description = "External IP of GCP HA VPN Gateway interface 0 — used as Customer Gateway 1."
  type        = string
}
variable "gcp_vpn_interface_1_ip" {
  description = "External IP of GCP HA VPN Gateway interface 1 — used as Customer Gateway 2."
  type        = string
}

# Subnet IDs in the EKS VPC to attach to the Transit Gateway
variable "private_subnet_ids" {
  description = "Private subnet IDs for the TGW VPC attachment (one per AZ recommended)."
  type        = list(string)
}

# Route table IDs to inject static GCP CIDR routes pointing at the TGW
variable "private_route_table_ids" {
  description = "Private route table IDs — GCP CIDRs will be routed via the Transit Gateway."
  type        = list(string)
}

variable "gcp_cidr_ranges" {
  description = "GCP CIDR blocks reachable via the VPN (spoke subnet, pod range, svc range)."
  type        = list(string)
  default     = ["10.16.0.0/20", "10.17.0.0/16", "10.18.0.0/20"]
}

# ── Pre-defined PSKs ────────────────────────────────────────────────────────────
# Choose 4 strong secrets (8-64 printable ASCII, no leading/trailing spaces)
# BEFORE applying, and paste the SAME values into infra/gcp/terraform.tfvars.
# This avoids reading sensitive terraform output between stacks.
#
# Connection 1  (Transit Gateway ↔ CGW1 / GCP interface 0)  →  tunnels 1 & 2
variable "conn1_t1_psk" {
  description = "PSK for connection 1, tunnel 1. Must match aws_conn1_t1_psk in infra/gcp."
  type        = string
  sensitive   = true
}
variable "conn1_t2_psk" {
  description = "PSK for connection 1, tunnel 2. Must match aws_conn1_t2_psk in infra/gcp."
  type        = string
  sensitive   = true
}

# Connection 2  (Transit Gateway ↔ CGW2 / GCP interface 1)  →  tunnels 3 & 4
variable "conn2_t1_psk" {
  description = "PSK for connection 2, tunnel 1. Must match aws_conn2_t1_psk in infra/gcp."
  type        = string
  sensitive   = true
}
variable "conn2_t2_psk" {
  description = "PSK for connection 2, tunnel 2. Must match aws_conn2_t2_psk in infra/gcp."
  type        = string
  sensitive   = true
}
