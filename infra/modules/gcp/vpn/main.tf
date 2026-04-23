terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

locals {
  # Gate: all tunnel resources are conditional on the first outside IP being set.
  # Phase 1 (apply -target="module.vpn_data") creates only the HA VPN Gateway
  # so its two interface IPs can be passed to AWS as Customer Gateways.
  tunnels_ready = var.aws_conn1_t1_outside_ip != ""
}

# ── HA VPN Gateway — 2 interfaces, active/active ─────────────────────────────
# Interface 0 → CGW1 (AWS VPN connection 1)
# Interface 1 → CGW2 (AWS VPN connection 2)
resource "google_compute_ha_vpn_gateway" "main" {
  name    = "${var.env_name}-ha-vpn-gw"
  network = var.vpc_id
  region  = var.region
}

# ── External VPN Gateway — represents the AWS Transit Gateway with 4 outside IPs ─
# FOUR_IPS_REDUNDANCY: 2 connections × 2 tunnels each = 4 distinct AWS endpoints.
# Must be created with all 4 outside IPs from the AWS VPN configuration download.
resource "google_compute_external_vpn_gateway" "aws_tgw" {
  count           = local.tunnels_ready ? 1 : 0
  name            = "${var.env_name}-aws-tgw-peer"
  redundancy_type = "FOUR_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = var.aws_conn1_t1_outside_ip  # conn1/tunnel1 outside IP
  }
  interface {
    id         = 1
    ip_address = var.aws_conn1_t2_outside_ip  # conn1/tunnel2 outside IP
  }
  interface {
    id         = 2
    ip_address = var.aws_conn2_t1_outside_ip  # conn2/tunnel1 outside IP
  }
  interface {
    id         = 3
    ip_address = var.aws_conn2_t2_outside_ip  # conn2/tunnel2 outside IP
  }
}

# ── Cloud Router — BGP ASN 65000, advertises GKE pod/service/subnet CIDRs ─────
resource "google_compute_router" "vpn" {
  count   = local.tunnels_ready ? 1 : 0
  name    = "${var.env_name}-vpn-router"
  network = var.vpc_id
  region  = var.region

  bgp {
    asn               = 65000
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

    # Explicitly advertise GKE pod and service CIDRs so EKS can route to them
    advertised_ip_ranges { range = var.pod_cidr }
    advertised_ip_ranges { range = var.service_cidr }
  }
}

# ── 4 VPN Tunnels (IKEv2) ─────────────────────────────────────────────────────
# tunnel-1: GCP interface 0 ↔ AWS conn1/tunnel1 (external gateway interface 0)
resource "google_compute_vpn_tunnel" "tunnel1" {
  count                           = local.tunnels_ready ? 1 : 0
  name                            = "${var.env_name}-tunnel1"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_tgw[0].id
  peer_external_gateway_interface = 0
  shared_secret                   = var.aws_conn1_t1_psk
  router                          = google_compute_router.vpn[0].id
  ike_version                     = 2
}

# tunnel-2: GCP interface 0 ↔ AWS conn1/tunnel2 (external gateway interface 1)
resource "google_compute_vpn_tunnel" "tunnel2" {
  count                           = local.tunnels_ready ? 1 : 0
  name                            = "${var.env_name}-tunnel2"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_tgw[0].id
  peer_external_gateway_interface = 1
  shared_secret                   = var.aws_conn1_t2_psk
  router                          = google_compute_router.vpn[0].id
  ike_version                     = 2
}

# tunnel-3: GCP interface 1 ↔ AWS conn2/tunnel1 (external gateway interface 2)
resource "google_compute_vpn_tunnel" "tunnel3" {
  count                           = local.tunnels_ready ? 1 : 0
  name                            = "${var.env_name}-tunnel3"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_tgw[0].id
  peer_external_gateway_interface = 2
  shared_secret                   = var.aws_conn2_t1_psk
  router                          = google_compute_router.vpn[0].id
  ike_version                     = 2
}

# tunnel-4: GCP interface 1 ↔ AWS conn2/tunnel2 (external gateway interface 3)
resource "google_compute_vpn_tunnel" "tunnel4" {
  count                           = local.tunnels_ready ? 1 : 0
  name                            = "${var.env_name}-tunnel4"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_tgw[0].id
  peer_external_gateway_interface = 3
  shared_secret                   = var.aws_conn2_t2_psk
  router                          = google_compute_router.vpn[0].id
  ike_version                     = 2
}

# ── Cloud Router Interfaces & BGP Peers (one per tunnel) ──────────────────────
# ip_range = GCP-side BGP IP with /30 (the cgw_inside_address from AWS output + /30)
# peer_ip_address = AWS/TGW-side BGP peer IP (the vgw_inside_address from AWS output)
# peer_asn = 64512 (Transit Gateway amazon_side_asn)

resource "google_compute_router_interface" "if1" {
  count      = local.tunnels_ready ? 1 : 0
  name       = "${var.env_name}-if1"
  router     = google_compute_router.vpn[0].name
  region     = var.region
  ip_range   = var.aws_conn1_t1_cgw_inside  # e.g. 169.254.x.x/30
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1[0].name
}
resource "google_compute_router_peer" "peer1" {
  count           = local.tunnels_ready ? 1 : 0
  name            = "${var.env_name}-peer1"
  router          = google_compute_router.vpn[0].name
  region          = var.region
  peer_ip_address = var.aws_conn1_t1_vgw_inside
  peer_asn        = 64512
  interface       = google_compute_router_interface.if1[0].name
}

resource "google_compute_router_interface" "if2" {
  count      = local.tunnels_ready ? 1 : 0
  name       = "${var.env_name}-if2"
  router     = google_compute_router.vpn[0].name
  region     = var.region
  ip_range   = var.aws_conn1_t2_cgw_inside
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2[0].name
}
resource "google_compute_router_peer" "peer2" {
  count           = local.tunnels_ready ? 1 : 0
  name            = "${var.env_name}-peer2"
  router          = google_compute_router.vpn[0].name
  region          = var.region
  peer_ip_address = var.aws_conn1_t2_vgw_inside
  peer_asn        = 64512
  interface       = google_compute_router_interface.if2[0].name
}

resource "google_compute_router_interface" "if3" {
  count      = local.tunnels_ready ? 1 : 0
  name       = "${var.env_name}-if3"
  router     = google_compute_router.vpn[0].name
  region     = var.region
  ip_range   = var.aws_conn2_t1_cgw_inside
  vpn_tunnel = google_compute_vpn_tunnel.tunnel3[0].name
}
resource "google_compute_router_peer" "peer3" {
  count           = local.tunnels_ready ? 1 : 0
  name            = "${var.env_name}-peer3"
  router          = google_compute_router.vpn[0].name
  region          = var.region
  peer_ip_address = var.aws_conn2_t1_vgw_inside
  peer_asn        = 64512
  interface       = google_compute_router_interface.if3[0].name
}

resource "google_compute_router_interface" "if4" {
  count      = local.tunnels_ready ? 1 : 0
  name       = "${var.env_name}-if4"
  router     = google_compute_router.vpn[0].name
  region     = var.region
  ip_range   = var.aws_conn2_t2_cgw_inside
  vpn_tunnel = google_compute_vpn_tunnel.tunnel4[0].name
}
resource "google_compute_router_peer" "peer4" {
  count           = local.tunnels_ready ? 1 : 0
  name            = "${var.env_name}-peer4"
  router          = google_compute_router.vpn[0].name
  region          = var.region
  peer_ip_address = var.aws_conn2_t2_vgw_inside
  peer_asn        = 64512
  interface       = google_compute_router_interface.if4[0].name
}
