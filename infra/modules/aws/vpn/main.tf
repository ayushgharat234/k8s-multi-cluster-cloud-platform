terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Virtual Private Gateway — AWS side of the VPN
resource "aws_vpn_gateway" "main" {
  vpc_id          = var.vpc_id
  amazon_side_asn = 64512
  tags            = { Name = "${var.env_name}-vgw" }
}

# Customer Gateway — represents GCP HA VPN Gateway interface 0
resource "aws_customer_gateway" "gcp" {
  bgp_asn    = 65000
  ip_address = var.gcp_vpn_gateway_ip
  type       = "ipsec.1"
  tags       = { Name = "${var.env_name}-cgw-gcp" }
}

# Site-to-Site VPN Connection (BGP / dynamic routing)
resource "aws_vpn_connection" "to_gcp" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.gcp.id
  type                = "ipsec.1"
  static_routes_only  = false

  tags = { Name = "${var.env_name}-vpn-to-gcp" }
}

# Propagate VPN routes to private route tables so EKS nodes know how to reach GCP
resource "aws_vpn_gateway_route_propagation" "private" {
  for_each       = toset(var.private_route_table_ids)
  vpn_gateway_id = aws_vpn_gateway.main.id
  route_table_id = each.value
}

# Allow GCP pod/service CIDRs into EKS cluster security group
resource "aws_security_group_rule" "allow_gcp_pods" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = var.gcp_cidr_ranges
  security_group_id = var.cluster_security_group_id
  description       = "Allow GCP pod and service CIDRs via VPN"
}
