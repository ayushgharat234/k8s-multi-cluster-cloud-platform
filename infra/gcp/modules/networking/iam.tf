variable "service_project_ids" {
  description = "List of Service Project IDs (Tenants) that need access"
  type        = list(string)
}

variable "service_project_numbers" {
  description = "List of Service Project Numbers (Tenants) that need access"
  type        = list(string)
}

# Allow GKE Robots to manage Host Network resources
resource "google_project_iam_member" "host_service_agent" {
  for_each = toset(var.service_project_numbers)

  project = var.project_id # Host Project ID
  role    = "roles/container.hostServiceAgentUser"
  member  = "serviceAccount:service-${each.value}@container-engine-robot.iam.gserviceaccount.com"
}

# Allow GKE Nodes to use the Subnet
resource "google_compute_subnetwork_iam_member" "network_user_cloudservices" {
  for_each = toset(var.service_project_numbers)

  subnetwork = google_compute_subnetwork.gke_subnet.name
  region     = var.region
  project    = var.project_id
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${each.value}@cloudservices.gserviceaccount.com"
}

# Allow GKE Robots to use the Subnet
resource "google_compute_subnetwork_iam_member" "network_user_robot" {
  for_each = toset(var.service_project_numbers)

  subnetwork = google_compute_subnetwork.gke_subnet.name
  region     = var.region
  project    = var.project_id
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${each.value}@container-engine-robot.iam.gserviceaccount.com"
}
