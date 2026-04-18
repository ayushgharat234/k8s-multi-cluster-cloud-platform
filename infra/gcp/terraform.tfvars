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
# Replace with your real domain.  After `terraform apply`, point this domain's
# A record to the `lb_global_ip` output so the managed cert can provision.
domain = "opsnexus.example.com"

# ─── GKE API SERVER ACCESS ───────────────────────────────────────────────────
# Add your workstation / VPN IP so kubectl can reach the private GKE API.
# Empty list = VPC-internal access only (safe default; add your IP to unblock).
master_authorized_cidr_blocks = [
  # {
  #   cidr_block   = "YOUR.PUBLIC.IP/32"
  #   display_name = "home-or-vpn"
  # }
]

# ─── MULTI-CLOUD FLEET (AWS EKS) ─────────────────────────────────────────────
# Populated in Wave 3 (after `terraform apply` in infra/aws):
#   make eks-oidc-url          → prints the URL
#   make apply-gcp-fleet       → applies with the URL automatically
eks_cluster_name = "opsnexus-eks-spoke"
eks_oidc_url     = ""   # Leave empty; pass via CLI during fleet wave

# ─── NETWORKING (legacy — kept for module compatibility) ─────────────────────
subnet_cidr  = "10.0.0.0/20"
pod_cidr     = "10.1.0.0/16"
service_cidr = "10.2.0.0/20"
