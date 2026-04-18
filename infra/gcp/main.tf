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
    "connectgateway.googleapis.com"
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
    "cloudkms.googleapis.com"
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
  source         = "../modules/gcp/gke"
  project_id     = var.data_plane_project_id
  project_number = var.data_plane_project_number
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

# --- GLOBAL LOAD BALANCER ---
module "lb" {
  source     = "../modules/gcp/lb"
  project_id = var.control_plane_project_id
  env_name   = var.env_name
  domain     = var.domain

  providers = {
    google = google.control
  }
}
