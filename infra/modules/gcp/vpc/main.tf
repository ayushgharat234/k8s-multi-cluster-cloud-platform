terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Custom VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.env_name}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Private Subnet with GKE Secondary Ranges
resource "google_compute_subnetwork" "subnet" {
  name                     = "${var.env_name}-subnet"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
  project                  = var.project_id

  secondary_ip_range {
    range_name    = "pod-range"
    ip_cidr_range = var.pod_cidr
  }

  secondary_ip_range {
    range_name    = "service-range"
    ip_cidr_range = var.service_cidr
  }
}

# Cloud Router (Needed for NAT)
resource "google_compute_router" "router" {
  name    = "${var.env_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
  project = var.project_id
}

# Cloud NAT: Allows private nodes to access the internet (for updates/registries)
resource "google_compute_router_nat" "nat" {
  name                               = "${var.env_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  project                            = var.project_id

  subnetwork {
    name                    = google_compute_subnetwork.subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall: GKE control plane → node kubelet and webhook traffic
# Restricted to specific ports required by GKE with Datapath V2 (eBPF)
resource "google_compute_firewall" "allow_gke_control_plane" {
  name    = "${var.env_name}-allow-gke-cp"
  network = google_compute_network.vpc.name
  project = var.project_id

  # Kubelet API (control plane→node health & exec)
  allow {
    protocol = "tcp"
    ports    = ["10250"]
  }
  # Admission webhooks (control plane→node webhook servers)
  allow {
    protocol = "tcp"
    ports    = ["443", "8443"]
  }

  source_ranges = [var.master_cidr]
  target_tags   = ["gke-node"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Firewall: Node-to-node + pod-to-pod internal traffic
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.env_name}-allow-internal"
  network = google_compute_network.vpc.name
  project = var.project_id

  # TCP: HTTPS, internal API, Cilium health, kubelet read-only (cluster-internal)
  allow {
    protocol = "tcp"
    ports    = ["443", "4240", "10250", "10255"]
  }
  # ICMP for health checks and ping
  allow {
    protocol = "icmp"
  }

  # Scoped to node/pod CIDRs of this VPC plus peered VPC ranges
  source_ranges = concat([var.subnet_cidr, var.pod_cidr], var.peer_cidr_ranges)
  target_tags   = ["gke-node"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
