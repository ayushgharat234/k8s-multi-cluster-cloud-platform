region       = "us-east-1"
env_name     = "opsnexus"
cluster_name = "opsnexus-eks-spoke"
vpc_cidr     = "172.16.0.0/16"

github_repo       = "ayushgharat234/k8s-multi-cluster-cloud-platform"
github_thumbprint = "6938fd4d98bab03faadb97b34396831e3780aea1"

# Get this with: gcloud iam service-accounts describe opsnexus-ci-sa@dotted-saga-493511-a1.iam.gserviceaccount.com --format="value(uniqueId)"
gcp_ci_sa_unique_id = "101269067509992697395"

# ─── SITE-TO-SITE VPN ─────────────────────────────────────────────────────────
# Architecture: GCP HA VPN Gateway (2 interfaces) ↔ AWS Transit Gateway (ECMP)
#   2 Customer Gateways × 1 VPN connection each × 2 tunnels = 4 tunnels total
#   Meets Google 99.99% SLA when all 4 BGP sessions are established.
#
# Phase 1 — Apply GCP stack gateway only, then collect both interface IPs:
#   terraform -chdir=infra/gcp apply -target="module.vpn_data"
#   terraform -chdir=infra/gcp output gcp_vpn_gateway_ip    → gcp_vpn_interface_0_ip
#   terraform -chdir=infra/gcp output gcp_vpn_gateway_ip_1  → gcp_vpn_interface_1_ip
#
# Phase 2 — Fill the values below and apply this (AWS) stack.
# Phase 3 — Collect VPN outputs, fill infra/gcp/terraform.tfvars, apply GCP.

# ── GCP HA VPN Gateway IPs (from Phase 1 output) ──
gcp_vpn_interface_0_ip = "FILL_AFTER_GCP_PHASE1_APPLY"   # terraform output gcp_vpn_gateway_ip
gcp_vpn_interface_1_ip = "FILL_AFTER_GCP_PHASE1_APPLY"   # terraform output gcp_vpn_gateway_ip_1

# ── Pre-shared Keys (4 tunnels = 4 PSKs) ──────────────────────────────────────
# Choose strong secrets before applying. Copy the SAME values to infra/gcp/terraform.tfvars.
# DO NOT commit real values to git — use TF_VAR_vpn_conn*_t*_psk env vars or a .env file.
vpn_conn1_t1_psk = "CHOOSE_STRONG_SECRET_CONN1_TUNNEL1"
vpn_conn1_t2_psk = "CHOOSE_STRONG_SECRET_CONN1_TUNNEL2"
vpn_conn2_t1_psk = "CHOOSE_STRONG_SECRET_CONN2_TUNNEL1"
vpn_conn2_t2_psk = "CHOOSE_STRONG_SECRET_CONN2_TUNNEL2"
