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
module "gke_mgmt" {
  source = "../../modules/gke"

  project_id   = var.management_project_id
  region       = var.region
  cluster_name = "platform-mgmt-prod-01"

  network_self_link             = module.networking.network_self_link
  subnet_self_link              = module.networking.subnet_self_link
  pods_secondary_range_name     = "gke-pods"
  services_secondary_range_name = "gke-services"
}

# --- Cluster 2: Tenant 1 (e.g. Americas) ---
module "gke_tenant_1" {
  source = "../../modules/gke"

  project_id   = var.tenant_1_project_id
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