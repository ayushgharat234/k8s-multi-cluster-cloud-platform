terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}

# 1. Workload Identity Pool
resource "google_iam_workload_identity_pool" "pool" {
  workload_identity_pool_id = "${var.env_name}-pool"
  display_name              = "OpsNexus CI/CD Pool"
  description               = "Identity pool for GitHub Actions and multi-cloud access"
  project                   = var.project_id
}

# 2. Workload Identity Provider for GitHub
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"
  project                            = var.project_id

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  # Restrict to the specific repo only — prevents other repos from assuming this identity
  attribute_condition = "attribute.repository == \"${var.github_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# 3. Service Account for CI/CD
resource "google_service_account" "ci_sa" {
  account_id   = "${var.env_name}-ci-sa"
  display_name = "OpsNexus CI Service Account"
  project      = var.project_id
}

# 4. Allow GitHub Actions to impersonate the CI SA via WIF
resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.ci_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.pool.name}/attribute.repository/${var.github_repo}"
}

# 5. Least-privilege roles for CI SA in the CONTROL project
# roles/editor is intentionally absent — replaced with specific roles
resource "google_project_iam_member" "control_roles" {
  for_each = toset([
    "roles/container.admin",               # GKE cluster & node pool management
    "roles/compute.networkAdmin",          # VPC, subnets, firewalls, Cloud NAT
    "roles/storage.admin",                 # GCS buckets (Terraform state, artifacts)
    "roles/artifactregistry.admin",        # Container image registry
    "roles/binaryauthorization.attestorsAdmin", # Binary Authorization attestors & policy
    "roles/cloudkms.admin",               # KMS key rings and crypto keys
    "roles/iam.serviceAccountAdmin",       # Create/manage service accounts
    "roles/iam.serviceAccountUser",        # Impersonate SAs (node SAs, etc.)
    "roles/resourcemanager.projectIamAdmin", # Required for Terraform to manage IAM bindings
    "roles/gkehub.admin",                  # Fleet membership and feature management
    "roles/containeranalysis.notes.editor", # Container Analysis notes for Binary Auth
    "roles/logging.admin",                 # Cloud Logging sink configuration
    "roles/logging.logWriter",             # Write Cloud Build logs (when used as Cloud Build SA)
    "roles/monitoring.admin",              # Cloud Monitoring configuration
    "roles/serviceusage.serviceUsageAdmin", # Enable GCP APIs
    "roles/clouddeploy.releaser",           # Create Cloud Deploy releases
    "roles/clouddeploy.viewer"              # Read Cloud Deploy pipeline state
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.ci_sa.email}"
}

# 5b. Roles for CI SA in the DATA project
resource "google_project_iam_member" "data_roles" {
  for_each = toset([
    "roles/container.admin",
    "roles/compute.networkAdmin",
    "roles/storage.admin",
    "roles/binaryauthorization.attestorsAdmin",
    "roles/cloudkms.cryptoKeyEncrypterDecrypter", # Use shared KMS keys from control project
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/resourcemanager.projectIamAdmin",
    "roles/containeranalysis.notes.editor",
    "roles/logging.admin",
    "roles/monitoring.admin",
    "roles/serviceusage.serviceUsageAdmin"
  ])
  project = var.data_plane_project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.ci_sa.email}"
}

# 6. Cross-project service agent permissions

# Allow Hub project's GKE Hub Service Agent to manage memberships in the Data project
resource "google_project_iam_member" "gke_hub_agent_data_access" {
  project = var.data_plane_project_id
  role    = "roles/gkehub.serviceAgent"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-gkehub.iam.gserviceaccount.com"
}

# Allow Hub project's Mesh Service Agent to operate in Data project
resource "google_project_iam_member" "mesh_agent_data_access" {
  project = var.data_plane_project_id
  role    = "roles/anthosservicemesh.serviceAgent"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-servicemesh.iam.gserviceaccount.com"
}

# 7. Wait for IAM propagation before cluster creation begins
resource "time_sleep" "wait_for_iam" {
  create_duration = "90s"

  depends_on = [
    google_project_iam_member.control_roles,
    google_project_iam_member.data_roles,
    google_project_iam_member.gke_hub_agent_data_access,
    google_project_iam_member.mesh_agent_data_access,
  ]
}
