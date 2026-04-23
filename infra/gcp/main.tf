# --- PROVIDERS ---
provider "google" {
  alias   = "control"
  project = var.control_plane_project_id
  region  = var.region
}

provider "google" {
  alias   = "data"
  project = var.data_plane_project_id
  region  = var.region
}

# --- API ENABLEMENT ---
resource "google_project_service" "control_apis" {
  for_each = toset([
    "anthosconfigmanagement.googleapis.com",
    "anthospolicycontroller.googleapis.com",
    "containeranalysis.googleapis.com",
    "mesh.googleapis.com",
    "anthos.googleapis.com",
    "meshca.googleapis.com",
    "meshconfig.googleapis.com",
    "gkehub.googleapis.com",
    "container.googleapis.com",
    "binaryauthorization.googleapis.com",
    "cloudkms.googleapis.com",
    "artifactregistry.googleapis.com",
    "clouddeploy.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "gkemulticloud.googleapis.com",
    "gkeconnect.googleapis.com",
    "connectgateway.googleapis.com",
    "certificatemanager.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "privateca.googleapis.com"
  ])
  project            = var.control_plane_project_id
  service            = each.key
  disable_on_destroy = false
  provider           = google.control
}

resource "google_project_service" "data_apis" {
  for_each = toset([
    "container.googleapis.com",
    "containeranalysis.googleapis.com",
    "binaryauthorization.googleapis.com",
    "cloudkms.googleapis.com",
    "mesh.googleapis.com",
    "anthos.googleapis.com",
    "meshca.googleapis.com",
    "meshconfig.googleapis.com",
    "gkehub.googleapis.com",
    "certificatemanager.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "compute.googleapis.com"
  ])
  project            = var.data_plane_project_id
  service            = each.key
  disable_on_destroy = false
  provider           = google.data
}

# --- WAIT FOR API PROPAGATION ---
# GKE and Fleet APIs can take 2+ minutes to be fully available after enablement
resource "time_sleep" "wait_for_apis" {
  create_duration = "120s"
  depends_on = [
    google_project_service.control_apis,
    google_project_service.data_apis
  ]
}

# --- VPC (CONTROL PLANE) ---
module "vpc_control" {
  source       = "../modules/gcp/vpc"
  project_id   = var.control_plane_project_id
  region       = var.region
  env_name     = "${var.env_name}-control"
  subnet_cidr  = "10.0.0.0/20"
  pod_cidr     = "10.1.0.0/16"
  service_cidr = "10.2.0.0/20"
  master_cidr  = "172.16.0.0/28" # Hub cluster master CIDR

  peer_cidr_ranges = ["10.16.0.0/20", "10.17.0.0/16"] # Data VPC ranges

  providers = {
    google = google.control
  }
}

# --- VPC (DATA PLANE) ---
module "vpc_data" {
  source       = "../modules/gcp/vpc"
  project_id   = var.data_plane_project_id
  region       = var.region
  env_name     = "${var.env_name}-data"
  subnet_cidr  = "10.16.0.0/20"
  pod_cidr     = "10.17.0.0/16"
  service_cidr = "10.18.0.0/20"
  master_cidr  = "172.16.0.16/28" # Spoke cluster master CIDR

  peer_cidr_ranges = ["10.0.0.0/20", "10.1.0.0/16"] # Control VPC ranges

  providers = {
    google = google.data
  }
}

# --- VPC PEERING (bidirectional, required for cross-project GKE Fleet comms) ---
resource "google_compute_network_peering" "control_to_data" {
  name         = "peering-control-to-data"
  network      = module.vpc_control.vpc_id
  peer_network = module.vpc_data.vpc_id

  export_custom_routes = true
  import_custom_routes = true

  provider = google.control
}

resource "google_compute_network_peering" "data_to_control" {
  name         = "peering-data-to-control"
  network      = module.vpc_data.vpc_id
  peer_network = module.vpc_control.vpc_id

  export_custom_routes = true
  import_custom_routes = true

  provider   = google.data
  depends_on = [google_compute_network_peering.control_to_data]
}

# --- KMS (Centralized in Control Project) ---
module "kms" {
  source                    = "../modules/gcp/kms"
  project_id                = var.control_plane_project_id
  project_number            = var.control_plane_project_number
  data_plane_project_number = var.data_plane_project_number
  region                    = var.region
  env_name                  = var.env_name

  providers = {
    google = google.control
  }

  depends_on = [time_sleep.wait_for_apis]
}

# --- CAS (Centralized in Control Project) ---
# Root CA + three subordinate CAs (mesh, internal-tls, workload).
# Inactive until wired to ASM or cert-manager; provisioning now ensures the
# PKI hierarchy is in place before workloads need it.
module "cas" {
  source                   = "../modules/gcp/cas"
  project_id               = var.control_plane_project_id
  region                   = var.region
  env_name                 = var.env_name
  organization             = var.organization
  ci_service_account_email = module.identity.service_account_email
  deletion_protection      = false

  providers = {
    google = google.control
  }

  depends_on = [
    time_sleep.wait_for_apis,
    module.identity,
  ]
}

# --- IDENTITY (Centralized in Control Project) ---
module "identity" {
  source                    = "../modules/gcp/identity"
  env_name                  = var.env_name
  project_id                = var.control_plane_project_id
  project_number            = var.control_plane_project_number
  data_plane_project_id     = var.data_plane_project_id
  data_plane_project_number = var.data_plane_project_number
  github_repo               = var.github_repo

  providers = {
    google = google.control
  }

  depends_on = [time_sleep.wait_for_apis]
}

# --- GKE HUB (Management Cluster — Control Project) ---
module "gke_hub" {
  source         = "../modules/gcp/gke"
  project_id     = var.control_plane_project_id
  project_number = var.control_plane_project_number
  region         = var.region
  env_name       = "${var.env_name}-hub"
  vpc_id         = module.vpc_control.vpc_id
  subnet_id      = module.vpc_control.subnet_id

  pod_range_name     = module.vpc_control.pod_range_name
  service_range_name = module.vpc_control.service_range_name

  kms_secret_key_id        = module.kms.gke_secret_key_id
  kms_disk_key_id          = module.kms.gke_disk_key_id
  kms_cosign_key_id        = module.kms.cosign_key_id
  kms_cosign_public_key_pem = module.kms.cosign_public_key_pem

  master_ipv4_cidr_block = "172.16.0.0/28"
  master_authorized_cidr_blocks = var.master_authorized_cidr_blocks

  node_count = 1

  providers = {
    google = google.control
  }

  depends_on = [module.identity, module.kms]
}

# --- GKE SPOKE (Workload Cluster — Data Project) ---
module "gke_spoke" {
  source           = "../modules/gcp/gke"
  project_id       = var.data_plane_project_id
  project_number   = var.data_plane_project_number
  fleet_project_id = var.control_plane_project_id
  region         = var.region
  env_name       = "${var.env_name}-spoke"
  vpc_id         = module.vpc_data.vpc_id
  subnet_id      = module.vpc_data.subnet_id

  pod_range_name     = module.vpc_data.pod_range_name
  service_range_name = module.vpc_data.service_range_name

  kms_secret_key_id        = module.kms.gke_secret_key_id # Shared cross-project KMS
  kms_disk_key_id          = module.kms.gke_disk_key_id
  kms_cosign_key_id        = module.kms.cosign_key_id
  kms_cosign_public_key_pem = module.kms.cosign_public_key_pem

  # Spoke BinAuth policy must accept the hub attestor (Cloud Build attests there)
  hub_attestor_resource_name = "projects/${var.control_plane_project_id}/attestors/opsnexus-hub-attestor"

  master_ipv4_cidr_block = "172.16.0.16/28"
  master_authorized_cidr_blocks = var.master_authorized_cidr_blocks

  node_count = 1

  providers = {
    google = google.data
  }

  depends_on = [module.identity, module.kms]
}

# --- FLEET & MESH (Managed from Control Project) ---
module "fleet" {
  source     = "../modules/gcp/fleet"
  project_id = var.control_plane_project_id
  clusters = {
    "gke-hub"   = { id = "${var.control_plane_project_id}/${var.region}/${module.gke_hub.cluster_name}" }
    "gke-spoke" = { id = "${var.data_plane_project_id}/${var.region}/${module.gke_spoke.cluster_name}" }
  }
  config_sync_repo    = var.config_sync_repo
  config_sync_branch  = var.config_sync_branch
  eks_membership_name = var.eks_membership_name

  providers = {
    google = google.control
  }

  # Clusters must exist before they can be registered to the fleet
  depends_on = [module.gke_hub, module.gke_spoke, time_sleep.wait_for_apis]
}

# --- FLEET CONNECT: EKS Attached Cluster ---
# Registers the AWS EKS spoke cluster into the GCP Fleet for unified multi-cloud management.
# Only activated when eks_oidc_url is provided (apply AWS stack first):
#   terraform apply -var="eks_oidc_url=$(cd ../aws && terraform output -raw oidc_provider_url)"
module "fleet_connect" {
  count = var.eks_oidc_url != "" ? 1 : 0

  source           = "../modules/aws/fleet-connect"
  project_id       = var.control_plane_project_id
  project_number   = var.control_plane_project_number
  env_name         = var.env_name
  cluster_name     = var.eks_cluster_name
  gcp_location     = var.region
  platform_version = "1.30.0-gke.1"
  eks_oidc_url     = var.eks_oidc_url

  providers = {
    google = google.control
  }

  depends_on = [module.fleet]
}

# --- ARTIFACT REGISTRY ---
resource "google_artifact_registry_repository" "images" {
  provider      = google.control
  project       = var.control_plane_project_id
  location      = var.region
  repository_id = "opsnexus"
  format        = "DOCKER"
  description   = "Container images for all OpsNexus services"

  depends_on = [google_project_service.control_apis]
}

# Grant the CI service account push access
resource "google_artifact_registry_repository_iam_member" "ci_writer" {
  provider   = google.control
  project    = var.control_plane_project_id
  location   = var.region
  repository = google_artifact_registry_repository.images.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${module.identity.service_account_email}"
}

# Grant GKE node SAs pull access (hub cluster)
resource "google_artifact_registry_repository_iam_member" "hub_node_reader" {
  provider   = google.control
  project    = var.control_plane_project_id
  location   = var.region
  repository = google_artifact_registry_repository.images.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${module.gke_hub.node_sa_email}"
}

# Grant GKE node SAs pull access (spoke cluster)
resource "google_artifact_registry_repository_iam_member" "spoke_node_reader" {
  provider   = google.control
  project    = var.control_plane_project_id
  location   = var.region
  repository = google_artifact_registry_repository.images.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${module.gke_spoke.node_sa_email}"
}

# --- EKS GAR PULLER (EKS nodes cannot use GKE WI, so we use a dedicated SA key
#     stored in Secret Manager — no static files, rotatable, auditable) ---
resource "google_service_account" "eks_puller_sa" {
  provider     = google.control
  account_id   = "eks-gar-puller"
  display_name = "EKS → GAR image puller (catalog)"
  project      = var.control_plane_project_id
}

resource "google_artifact_registry_repository_iam_member" "eks_puller_reader" {
  provider   = google.control
  project    = var.control_plane_project_id
  location   = var.region
  repository = google_artifact_registry_repository.images.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.eks_puller_sa.email}"
}

resource "google_service_account_key" "eks_puller_key" {
  provider           = google.control
  service_account_id = google_service_account.eks_puller_sa.name
}

resource "google_secret_manager_secret" "eks_puller_key" {
  provider  = google.control
  project   = var.control_plane_project_id
  secret_id = "eks-gar-puller-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.control_apis]
}

resource "google_secret_manager_secret_version" "eks_puller_key" {
  provider    = google.control
  secret      = google_secret_manager_secret.eks_puller_key.id
  secret_data = base64decode(google_service_account_key.eks_puller_key.private_key)
}

# CI SA needs to read this secret to populate the EKS pull secret in pipelines if needed
resource "google_secret_manager_secret_iam_member" "ci_reads_puller_key" {
  provider  = google.control
  project   = var.control_plane_project_id
  secret_id = google_secret_manager_secret.eks_puller_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.identity.service_account_email}"
}

# --- PAYMENT WORKLOAD IDENTITY ---
# The payment service runs on GKE and calls GCP Secret Manager via Workload Identity.
# This GCP SA is what the K8s SA (payment-sa) impersonates at runtime.
resource "google_service_account" "payment_sa" {
  provider     = google.control
  account_id   = "opsnexus-payment-sa"
  display_name = "Payment Service — GKE Workload Identity SA"
  project      = var.control_plane_project_id
}

resource "google_project_iam_member" "payment_secret_accessor" {
  provider = google.control
  project  = var.control_plane_project_id
  role     = "roles/secretmanager.secretAccessor"
  member   = "serviceAccount:${google_service_account.payment_sa.email}"
}

# Allow the K8s SA (payment-sa in nexus-app namespace on GKE Spoke) to impersonate this GCP SA
resource "google_service_account_iam_member" "payment_wif_binding" {
  provider           = google.control
  service_account_id = google_service_account.payment_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.data_plane_project_id}.svc.id.goog[nexus-app/payment-sa]"
}

# --- BINAUTHZ CROSS-PROJECT: allow spoke's BinAuth SA to verify hub attestor ---
# The spoke cluster (data-493511) must verify attestations created in the control
# project (dotted-saga-493511-a1) by opsnexus-hub-attestor.
resource "google_project_iam_member" "spoke_binauthz_verifier" {
  provider = google.control
  project  = var.control_plane_project_id
  role     = "roles/binaryauthorization.attestorsVerifier"
  member   = "serviceAccount:service-${var.data_plane_project_number}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"
}

# --- CLOUD BUILD SA PERMISSIONS ---
# Grant Cloud Build's service agent permission to run builds as opsnexus-ci-sa.
# This means builds run with CI SA's permissions (AR writer, KMS signer, Cloud Deploy releaser)
# instead of needing to grant each permission to the Cloud Build SA separately.
resource "google_service_account_iam_member" "cloudbuild_use_ci_sa" {
  provider           = google.control
  service_account_id = "projects/${var.control_plane_project_id}/serviceAccounts/${module.identity.service_account_email}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${var.control_plane_project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
  depends_on         = [module.identity]
}

# ─── SITE-TO-SITE VPN TO AWS (Data VPC — where GKE spoke lives) ──────────────────
# 4-tunnel HA VPN using Transit Gateway on AWS side for ECMP (99.99% SLA).
# Deployment uses a 3-phase workflow — see infra/gcp/terraform.tfvars for details.
module "vpn_data" {
  source = "../modules/gcp/vpn"

  env_name     = "${var.env_name}-data"
  vpc_id       = module.vpc_data.vpc_id
  region       = var.region
  pod_cidr     = "10.17.0.0/16"
  service_cidr = "10.18.0.0/20"

  # Connection 1 (GCP interface 0 ↔ AWS Transit Gateway via CGW1) — tunnels 1 & 2
  aws_conn1_t1_outside_ip = var.aws_conn1_t1_outside_ip
  aws_conn1_t1_psk        = var.aws_conn1_t1_psk
  aws_conn1_t1_cgw_inside = var.aws_conn1_t1_cgw_inside
  aws_conn1_t1_vgw_inside = var.aws_conn1_t1_vgw_inside

  aws_conn1_t2_outside_ip = var.aws_conn1_t2_outside_ip
  aws_conn1_t2_psk        = var.aws_conn1_t2_psk
  aws_conn1_t2_cgw_inside = var.aws_conn1_t2_cgw_inside
  aws_conn1_t2_vgw_inside = var.aws_conn1_t2_vgw_inside

  # Connection 2 (GCP interface 1 ↔ AWS Transit Gateway via CGW2) — tunnels 3 & 4
  aws_conn2_t1_outside_ip = var.aws_conn2_t1_outside_ip
  aws_conn2_t1_psk        = var.aws_conn2_t1_psk
  aws_conn2_t1_cgw_inside = var.aws_conn2_t1_cgw_inside
  aws_conn2_t1_vgw_inside = var.aws_conn2_t1_vgw_inside

  aws_conn2_t2_outside_ip = var.aws_conn2_t2_outside_ip
  aws_conn2_t2_psk        = var.aws_conn2_t2_psk
  aws_conn2_t2_cgw_inside = var.aws_conn2_t2_cgw_inside
  aws_conn2_t2_vgw_inside = var.aws_conn2_t2_vgw_inside

  providers = {
    google = google.data
  }

  depends_on = [module.vpc_data]
}

# --- GLOBAL LOAD BALANCER ---
# Lives in the data project so backend services can reference NEGs (cross-project NEGs are not allowed).
module "lb" {
  source     = "../modules/gcp/lb"
  project_id = var.data_plane_project_id
  env_name   = var.env_name
  domain     = var.domain

  dns_zone_dns_name = var.dns_zone_dns_name

  frontend_neg_ids = var.frontend_neg_ids
  payment_neg_ids  = var.payment_neg_ids

  iap_client_id     = var.iap_client_id
  iap_client_secret = var.iap_client_secret
  iap_members       = var.iap_members

  providers = {
    google = google.data
  }

  depends_on = [google_project_service.data_apis]
}

# --- FIREWALL: Allow Google Front End health-check probes to GKE spoke nodes ---
# Source ranges are the GFE and health-check IP ranges published by Google.
resource "google_compute_firewall" "allow_lb_health_checks" {
  provider = google.data
  name     = "${var.env_name}-allow-lb-hc"
  project  = var.data_plane_project_id
  network  = module.vpc_data.vpc_id

  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]

  target_tags = ["gke-node"]
}
