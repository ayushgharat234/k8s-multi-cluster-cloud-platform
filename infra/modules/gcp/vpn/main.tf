terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# HA VPN Gateway — two interfaces for active/active redundancy
resource "google_compute_ha_vpn_gateway" "main" {
  name    = "${var.env_name}-ha-vpn-gw"
  network = var.vpc_id
  region  = var.region
}

# External gateway object representing the AWS VPN endpoint
resource "google_compute_external_vpn_gateway" "aws" {
  count           = var.aws_tunnel1_address != "" ? 1 : 0
  name            = "${var.env_name}-aws-vpn-gw"
  redundancy_type = "TWO_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = var.aws_tunnel1_address
  }
  interface {
    id         = 1
    ip_address = var.aws_tunnel2_address
  }
}

# Cloud Router for BGP — advertises GCP pod/service CIDRs to AWS
resource "google_compute_router" "vpn" {
  count   = var.aws_tunnel1_address != "" ? 1 : 0
  name    = "${var.env_name}-vpn-router"
  network = var.vpc_id
  region  = var.region

  bgp {
    asn               = 65000
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

    # Advertise GKE pod and service CIDRs explicitly so EKS can route to them
    advertised_ip_ranges {
      range = var.pod_cidr
    }
    advertised_ip_ranges {
      range = var.service_cidr
    }
  }
}

# VPN Tunnel 1
resource "google_compute_vpn_tunnel" "tunnel1" {
  count                           = var.aws_tunnel1_address != "" ? 1 : 0
  name                            = "${var.env_name}-tunnel1"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.aws[0].id
  peer_external_gateway_interface = 0
  shared_secret                   = var.aws_tunnel1_psk
  router                          = google_compute_router.vpn[0].id
  ike_version                     = 2
}

# VPN Tunnel 2
resource "google_compute_vpn_tunnel" "tunnel2" {
  count                           = var.aws_tunnel2_address != "" ? 1 : 0
  name                            = "${var.env_name}-tunnel2"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.aws[0].id
  peer_external_gateway_interface = 1
  shared_secret                   = var.aws_tunnel2_psk
  router                          = google_compute_router.vpn[0].id
  ike_version                     = 2
}

# BGP interface + peer for Tunnel 1
resource "google_compute_router_interface" "if1" {
  count      = var.aws_tunnel1_address != "" ? 1 : 0
  name       = "${var.env_name}-if1"
  router     = google_compute_router.vpn[0].name
  region     = var.region
  ip_range   = var.aws_tunnel1_cgw_inside_address
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1[0].name
}

resource "google_compute_router_peer" "peer1" {
  count           = var.aws_tunnel1_address != "" ? 1 : 0
  name            = "${var.env_name}-peer1"
  router          = google_compute_router.vpn[0].name
  region          = var.region
  peer_ip_address = var.aws_tunnel1_vgw_inside_address
  peer_asn        = 64512
  interface       = google_compute_router_interface.if1[0].name
}

# BGP interface + peer for Tunnel 2
resource "google_compute_router_interface" "if2" {
  count      = var.aws_tunnel2_address != "" ? 1 : 0
  name       = "${var.env_name}-if2"
  router     = google_compute_router.vpn[0].name
  region     = var.region
  ip_range   = var.aws_tunnel2_cgw_inside_address
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2[0].name
}

resource "google_compute_router_peer" "peer2" {
  count           = var.aws_tunnel2_address != "" ? 1 : 0
  name            = "${var.env_name}-peer2"
  router          = google_compute_router.vpn[0].name
  region          = var.region
  peer_ip_address = var.aws_tunnel2_vgw_inside_address
  peer_asn        = 64512
  interface       = google_compute_router_interface.if2[0].name
}
