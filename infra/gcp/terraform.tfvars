# ─── PROJECTS ────────────────────────────────────────────────────────────────
control_plane_project_id     = "dotted-saga-493511-a1"
control_plane_project_number = "630558234054"
data_plane_project_id        = "data-493511"
data_plane_project_number    = "31478027028"

# ─── REGION / ENV ────────────────────────────────────────────────────────────
region   = "us-central1"
env_name = "opsnexus"

# ─── CI/CD ───────────────────────────────────────────────────────────────────
github_repo = "Vidvatta-Learn/vidvatta-lms-genai"

# ─── LOAD BALANCER ───────────────────────────────────────────────────────────
domain = "opsnexus.example.com"

# ─── GKE API SERVER ACCESS ───────────────────────────────────────────────────
master_authorized_cidr_blocks = [
  # {
  #   cidr_block   = "YOUR.PUBLIC.IP/32"
  #   display_name = "home-or-vpn"
  # }
]

# ─── CONFIG SYNC ─────────────────────────────────────────────────────────────
config_sync_repo   = "https://github.com/ayushgharat234/k8s-multi-cluster-cloud-platform"
config_sync_branch  = "prod"

# ─── MULTI-CLOUD FLEET (AWS EKS) ─────────────────────────────────────────────
eks_cluster_name = "opsnexus-eks-spoke"
eks_oidc_url     = ""   # Leave empty; pass via CLI during fleet wave

# ─── NETWORKING (legacy — kept for module compatibility) ─────────────────────
subnet_cidr  = "10.0.0.0/20"
pod_cidr     = "10.1.0.0/16"
service_cidr = "10.2.0.0/20"

# ─── SITE-TO-SITE VPN (GKE spoke ↔ EKS via Transit Gateway) ─────────────────
# Architecture: GCP HA VPN Gateway (2 interfaces) ↔ AWS Transit Gateway (ECMP)
#   CGW1 ← GCP interface 0 ─── VPN Connection 1 ─── tunnel-1, tunnel-2
#   CGW2 ← GCP interface 1 ─── VPN Connection 2 ─── tunnel-3, tunnel-4
#   Total: 4 tunnels, 4 BGP sessions → 99.99% SLA with ECMP load distribution.
#
# Deployment:
#   Phase 1: terraform apply -target="module.vpn_data"  (in this dir)
#            → collect gcp_vpn_gateway_ip and gcp_vpn_gateway_ip_1 outputs
#            → set gcp_vpn_interface_0_ip / gcp_vpn_interface_1_ip in infra/aws/terraform.tfvars
#   Phase 2: terraform apply  (in infra/aws, with both GCP IPs + PSKs set)
#            → collect all 12 vpn_conn* outputs (outside IPs, cgw/vgw inside addrs)
#   Phase 3: fill the values below (uncomment is already done), then: terraform apply

# ── Connection 1 (GCP interface 0 ↔ Transit Gateway via CGW1) — tunnels 1 & 2 ──
aws_conn1_t1_outside_ip = "FILL_FROM_AWS_OUTPUT_vpn_conn1_t1_outside_ip"
aws_conn1_t1_psk        = "CHOOSE_STRONG_SECRET_CONN1_TUNNEL1"            # same as vpn_conn1_t1_psk in infra/aws
aws_conn1_t1_cgw_inside = "FILL_FROM_AWS_OUTPUT_vpn_conn1_t1_cgw_inside_address_APPEND_SLASH30"
aws_conn1_t1_vgw_inside = "FILL_FROM_AWS_OUTPUT_vpn_conn1_t1_vgw_inside_address"

aws_conn1_t2_outside_ip = "FILL_FROM_AWS_OUTPUT_vpn_conn1_t2_outside_ip"
aws_conn1_t2_psk        = "CHOOSE_STRONG_SECRET_CONN1_TUNNEL2"            # same as vpn_conn1_t2_psk in infra/aws
aws_conn1_t2_cgw_inside = "FILL_FROM_AWS_OUTPUT_vpn_conn1_t2_cgw_inside_address_APPEND_SLASH30"
aws_conn1_t2_vgw_inside = "FILL_FROM_AWS_OUTPUT_vpn_conn1_t2_vgw_inside_address"

# ── Connection 2 (GCP interface 1 ↔ Transit Gateway via CGW2) — tunnels 3 & 4 ──
aws_conn2_t1_outside_ip = "FILL_FROM_AWS_OUTPUT_vpn_conn2_t1_outside_ip"
aws_conn2_t1_psk        = "CHOOSE_STRONG_SECRET_CONN2_TUNNEL1"            # same as vpn_conn2_t1_psk in infra/aws
aws_conn2_t1_cgw_inside = "FILL_FROM_AWS_OUTPUT_vpn_conn2_t1_cgw_inside_address_APPEND_SLASH30"
aws_conn2_t1_vgw_inside = "FILL_FROM_AWS_OUTPUT_vpn_conn2_t1_vgw_inside_address"

aws_conn2_t2_outside_ip = "FILL_FROM_AWS_OUTPUT_vpn_conn2_t2_outside_ip"
aws_conn2_t2_psk        = "CHOOSE_STRONG_SECRET_CONN2_TUNNEL2"            # same as vpn_conn2_t2_psk in infra/aws
aws_conn2_t2_cgw_inside = "FILL_FROM_AWS_OUTPUT_vpn_conn2_t2_cgw_inside_address_APPEND_SLASH30"
aws_conn2_t2_vgw_inside = "FILL_FROM_AWS_OUTPUT_vpn_conn2_t2_vgw_inside_address"
