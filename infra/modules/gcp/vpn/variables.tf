variable "env_name"     { type = string }
variable "vpc_id"       { type = string }
variable "region"       { type = string }
variable "pod_cidr"     { type = string }
variable "service_cidr" { type = string }

# Gate: tunnels are only provisioned when conn1_t1_outside_ip is non-empty.
# Phase 1 (terraform apply -target="module.vpn_data") skips all resources
# below the HA VPN gateway itself — only the 2-interface gateway is created
# to obtain the external IPs needed for AWS Customer Gateways.

# ── Connection 1 (GCP interface 0 ↔ Transit Gateway via CGW1) ─────────────────
# Maps to: GCP tunnel-1 and tunnel-2
variable "aws_conn1_t1_outside_ip" {
  description = "AWS outside IP for conn1/tunnel1 — GCP external VPN gateway interface 0."
  type        = string
  default     = ""
}
variable "aws_conn1_t1_psk" {
  description = "PSK for conn1/tunnel1. Must match conn1_t1_psk in infra/aws/terraform.tfvars."
  type        = string
  default     = ""
  sensitive   = true
}
variable "aws_conn1_t1_cgw_inside" {
  description = "GCP BGP IP with /30 mask for conn1/tunnel1 (e.g. 169.254.x.x/30)."
  type        = string
  default     = ""
}
variable "aws_conn1_t1_vgw_inside" {
  description = "AWS/TGW BGP peer IP for conn1/tunnel1."
  type        = string
  default     = ""
}

variable "aws_conn1_t2_outside_ip" {
  description = "AWS outside IP for conn1/tunnel2 — GCP external VPN gateway interface 1."
  type        = string
  default     = ""
}
variable "aws_conn1_t2_psk" {
  description = "PSK for conn1/tunnel2. Must match conn1_t2_psk in infra/aws/terraform.tfvars."
  type        = string
  default     = ""
  sensitive   = true
}
variable "aws_conn1_t2_cgw_inside" {
  description = "GCP BGP IP with /30 mask for conn1/tunnel2 (e.g. 169.254.x.x/30)."
  type        = string
  default     = ""
}
variable "aws_conn1_t2_vgw_inside" {
  description = "AWS/TGW BGP peer IP for conn1/tunnel2."
  type        = string
  default     = ""
}

# ── Connection 2 (GCP interface 1 ↔ Transit Gateway via CGW2) ─────────────────
# Maps to: GCP tunnel-3 and tunnel-4
variable "aws_conn2_t1_outside_ip" {
  description = "AWS outside IP for conn2/tunnel1 — GCP external VPN gateway interface 2."
  type        = string
  default     = ""
}
variable "aws_conn2_t1_psk" {
  description = "PSK for conn2/tunnel1. Must match conn2_t1_psk in infra/aws/terraform.tfvars."
  type        = string
  default     = ""
  sensitive   = true
}
variable "aws_conn2_t1_cgw_inside" {
  description = "GCP BGP IP with /30 mask for conn2/tunnel1 (e.g. 169.254.x.x/30)."
  type        = string
  default     = ""
}
variable "aws_conn2_t1_vgw_inside" {
  description = "AWS/TGW BGP peer IP for conn2/tunnel1."
  type        = string
  default     = ""
}

variable "aws_conn2_t2_outside_ip" {
  description = "AWS outside IP for conn2/tunnel2 — GCP external VPN gateway interface 3."
  type        = string
  default     = ""
}
variable "aws_conn2_t2_psk" {
  description = "PSK for conn2/tunnel2. Must match conn2_t2_psk in infra/aws/terraform.tfvars."
  type        = string
  default     = ""
  sensitive   = true
}
variable "aws_conn2_t2_cgw_inside" {
  description = "GCP BGP IP with /30 mask for conn2/tunnel2 (e.g. 169.254.x.x/30)."
  type        = string
  default     = ""
}
variable "aws_conn2_t2_vgw_inside" {
  description = "AWS/TGW BGP peer IP for conn2/tunnel2."
  type        = string
  default     = ""
}
