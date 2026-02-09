<<<<<<< HEAD
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
=======
module "networking" {
  source = "../../modules/networking"

  project_id    = var.project_id
  region        = var.region
  vpc_name      = "platform-shared-vpc-prod"
  subnet_name   = "gke-subnet-prod-us-central1"
  subnet_cidr   = var.subnet_cidr
  pods_cidr     = var.pods_cidr
  services_cidr = var.services_cidr

  # IAM: Allow these Service Projects to use the Host Network
  service_project_ids     = var.service_project_ids
  service_project_numbers = var.service_project_numbers
}

# --- Cluster 1: Management (Crossplane) ---
>>>>>>> 13ecf8215ba1cb907d6f19350cce36e84035375c
module "gke_mgmt" {
  source = "../../modules/gke"

  project_id   = var.management_project_id
<<<<<<< HEAD
  cluster_name = "platform-mgmt-prod-01"
  region       = var.region
  network      = module.networking.network_self_link
  subnetwork   = module.networking.subnets_self_links["mgmt-subnet"]
  
  # Phase 2: Enable Managed Prometheus
  monitoring_config = {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
}

=======
  region       = var.region
  cluster_name = "platform-mgmt-prod-01"

  network_self_link             = module.networking.network_self_link
  subnet_self_link              = module.networking.subnet_self_link
  pods_secondary_range_name     = "gke-pods"
  services_secondary_range_name = "gke-services"
}

# --- Cluster 2: Tenant 1 (e.g. Americas) ---
>>>>>>> 13ecf8215ba1cb907d6f19350cce36e84035375c
module "gke_tenant_1" {
  source = "../../modules/gke"

  project_id   = var.tenant_1_project_id
<<<<<<< HEAD
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
=======
  region       = var.region
  cluster_name = "platform-tenant-prod-01"

  network_self_link             = module.networking.network_self_link
  subnet_self_link              = module.networking.subnet_self_link
  pods_secondary_range_name     = "gke-pods"
  services_secondary_range_name = "gke-services"
}

# --- Cluster 3: Tenant 2 (e.g. Europe) ---
module "gke_tenant_2" {
  source = "../../modules/gke"

  project_id   = var.tenant_2_project_id
  region       = var.region
  cluster_name = "platform-tenant-prod-02"

  network_self_link             = module.networking.network_self_link
  subnet_self_link              = module.networking.subnet_self_link
  pods_secondary_range_name     = "gke-pods"
  services_secondary_range_name = "gke-services"
}
>>>>>>> 13ecf8215ba1cb907d6f19350cce36e84035375c
