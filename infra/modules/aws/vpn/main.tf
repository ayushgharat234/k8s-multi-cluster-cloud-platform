terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ── Transit Gateway ─────────────────────────────────────────────────────────────
# ECMP support distributes traffic equally across all 4 active tunnels.
# Google recommends Transit Gateway over Virtual Private Gateway for GCP HA VPN
# because VGW only activates one tunnel at a time (no ECMP).
resource "aws_ec2_transit_gateway" "main" {
  description                     = "${var.env_name} Transit Gateway — GCP HA VPN hub (4 tunnels)"
  amazon_side_asn                 = 64512    # Must match peer_asn in GCP Cloud Router peers
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  vpn_ecmp_support                = "enable" # Required for multi-tunnel active/active
  dns_support                     = "enable"

  tags = { Name = "${var.env_name}-tgw" }
}

# ── VPC Attachment — connects EKS VPC to the Transit Gateway ──
resource "aws_ec2_transit_gateway_vpc_attachment" "eks" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids

  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = { Name = "${var.env_name}-tgw-eks-attach" }
}

# ── Customer Gateway 1 — represents GCP HA VPN interface 0 ─────────────────────
resource "aws_customer_gateway" "cgw1" {
  bgp_asn    = 65000                       # Must match GCP Cloud Router ASN
  ip_address = var.gcp_vpn_interface_0_ip  # GCP HA VPN gateway interface 0
  type       = "ipsec.1"
  tags       = { Name = "${var.env_name}-cgw1-gcp-if0" }
}

# ── Customer Gateway 2 — represents GCP HA VPN interface 1 ─────────────────────
resource "aws_customer_gateway" "cgw2" {
  bgp_asn    = 65000                       # Must match GCP Cloud Router ASN
  ip_address = var.gcp_vpn_interface_1_ip  # GCP HA VPN gateway interface 1
  type       = "ipsec.1"
  tags       = { Name = "${var.env_name}-cgw2-gcp-if1" }
}

# ── VPN Connection 1 — Transit Gateway ↔ CGW1 (GCP interface 0) ─────────────────
# Generates 2 tunnels (tunnel-1 and tunnel-2 on GCP side).
resource "aws_vpn_connection" "conn1" {
  transit_gateway_id    = aws_ec2_transit_gateway.main.id
  customer_gateway_id   = aws_customer_gateway.cgw1.id
  type                  = "ipsec.1"
  static_routes_only    = false  # BGP / dynamic routing

  tunnel1_preshared_key = var.conn1_t1_psk
  tunnel2_preshared_key = var.conn1_t2_psk

  tags = { Name = "${var.env_name}-vpn-conn1-gcp-if0" }
}

# ── VPN Connection 2 — Transit Gateway ↔ CGW2 (GCP interface 1) ─────────────────
# Generates 2 more tunnels (tunnel-3 and tunnel-4 on GCP side).
resource "aws_vpn_connection" "conn2" {
  transit_gateway_id    = aws_ec2_transit_gateway.main.id
  customer_gateway_id   = aws_customer_gateway.cgw2.id
  type                  = "ipsec.1"
  static_routes_only    = false  # BGP / dynamic routing

  tunnel1_preshared_key = var.conn2_t1_psk
  tunnel2_preshared_key = var.conn2_t2_psk

  tags = { Name = "${var.env_name}-vpn-conn2-gcp-if1" }
}

# ── Static routes in EKS VPC private route tables → Transit Gateway ─────────────
# Routes GCP pod, service, and subnet CIDRs through the TGW so EKS nodes
# can reach GKE pods and services without additional BGP configuration on the VPC side.
resource "aws_route" "to_gcp" {
  for_each = {
    for pair in setproduct(var.private_route_table_ids, var.gcp_cidr_ranges) :
    "${pair[0]}-${replace(pair[1], "/", "_")}" => { rtb = pair[0], cidr = pair[1] }
  }

  route_table_id         = each.value.rtb
  destination_cidr_block = each.value.cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.eks]
}

# ── Ingress rule: allow GCP pod/service CIDRs into EKS cluster security group ──
resource "aws_security_group_rule" "allow_gcp_pods" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = var.gcp_cidr_ranges
  security_group_id = var.cluster_security_group_id
  description       = "Allow GCP pod and service CIDRs inbound via Transit Gateway VPN"
}
