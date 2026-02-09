terraform {
  backend "gcs" {
    bucket = "platform-tf-state-prod"
    prefix = "terraform/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# --- Module: Networking (Foundation) ---
module "networking" {
  source = "../../modules/networking"

  project_id = var.project_id
  region     = var.region
  
  # Shared VPC Configuration
  network_name = "shared-vpc-prod"
  subnets      = [
    {
      name          = "mgmt-subnet"
      ip_cidr_range = "10.0.1.0/24"
      region        = var.region
    },
    {
      name          = "tenant-1-subnet"
      ip_cidr_range = "10.0.2.0/24"
      region        = var.region
    },
    {
      name          = "tenant-2-subnet"
      ip_cidr_range = "10.0.3.0/24"
      region        = "europe-west1" # Multi-Region
    }
  ]
}

# --- Module: GKE Clusters (Compute) ---
module "gke_mgmt" {
  source = "../../modules/gke"

  project_id   = var.management_project_id
  cluster_name = "platform-mgmt-prod-01"
  region       = var.region
  network      = module.networking.network_self_link
  subnetwork   = module.networking.subnets_self_links["mgmt-subnet"]
  
  # Phase 2: Enable Managed Prometheus
  monitoring_config = {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
}

module "gke_tenant_1" {
  source = "../../modules/gke"

  project_id   = var.tenant_1_project_id
  cluster_name = "platform-tenant-prod-01"
  region       = var.region
  network      = module.networking.network_self_link
  subnetwork   = module.networking.subnets_self_links["tenant-1-subnet"]
  
  # Phase 2: Enable Binary Authorization
  binary_authorization = {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }
}

# --- Module: Artifact Registry (Secure Supply Chain) ---
module "artifact_registry" {
  source = "../../modules/artifact_registry"

  project_id    = var.project_id
  region        = var.region
  repository_id = "app-images-secure"
  format        = "DOCKER"
  description   = "Secure Repository for Production Images (Signed & Scanned)"
}

module "helm_registry" {
  source = "../../modules/artifact_registry"

  project_id    = var.project_id
  region        = var.region
  repository_id = "helm-charts-secure"
  format        = "DOCKER" # OCI based Helm
  description   = "Secure Repository for Helm Charts"
}

# --- Module: Security (The Shield) ---
module "security_foundation" {
  source = "../../modules/security"

  project_id = var.project_id
  region     = var.region
}
