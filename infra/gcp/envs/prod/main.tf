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

provider "google" {
  project = var.project_id
  region  = var.region
}