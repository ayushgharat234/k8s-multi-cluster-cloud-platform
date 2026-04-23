# ── Connection 1 (TGW ↔ CGW1 / GCP interface 0) — tunnels 1 & 2 ──────────────
output "conn1_t1_outside_ip" {
  description = "AWS outside IP for connection 1, tunnel 1 — GCP external VPN gateway interface 0."
  value       = aws_vpn_connection.conn1.tunnel1_address
}
output "conn1_t1_cgw_inside_address" {
  description = "GCP-side BGP IP (169.254.x.x) for conn1/tunnel1 — append /30 when passing to infra/gcp."
  value       = aws_vpn_connection.conn1.tunnel1_cgw_inside_address
}
output "conn1_t1_vgw_inside_address" {
  description = "AWS/TGW-side BGP peer IP for conn1/tunnel1."
  value       = aws_vpn_connection.conn1.tunnel1_vgw_inside_address
}

output "conn1_t2_outside_ip" {
  description = "AWS outside IP for connection 1, tunnel 2 — GCP external VPN gateway interface 1."
  value       = aws_vpn_connection.conn1.tunnel2_address
}
output "conn1_t2_cgw_inside_address" {
  description = "GCP-side BGP IP (169.254.x.x) for conn1/tunnel2 — append /30 when passing to infra/gcp."
  value       = aws_vpn_connection.conn1.tunnel2_cgw_inside_address
}
output "conn1_t2_vgw_inside_address" {
  description = "AWS/TGW-side BGP peer IP for conn1/tunnel2."
  value       = aws_vpn_connection.conn1.tunnel2_vgw_inside_address
}

# ── Connection 2 (TGW ↔ CGW2 / GCP interface 1) — tunnels 3 & 4 ──────────────
output "conn2_t1_outside_ip" {
  description = "AWS outside IP for connection 2, tunnel 1 — GCP external VPN gateway interface 2."
  value       = aws_vpn_connection.conn2.tunnel1_address
}
output "conn2_t1_cgw_inside_address" {
  description = "GCP-side BGP IP (169.254.x.x) for conn2/tunnel1 — append /30 when passing to infra/gcp."
  value       = aws_vpn_connection.conn2.tunnel1_cgw_inside_address
}
output "conn2_t1_vgw_inside_address" {
  description = "AWS/TGW-side BGP peer IP for conn2/tunnel1."
  value       = aws_vpn_connection.conn2.tunnel1_vgw_inside_address
}

output "conn2_t2_outside_ip" {
  description = "AWS outside IP for connection 2, tunnel 2 — GCP external VPN gateway interface 3."
  value       = aws_vpn_connection.conn2.tunnel2_address
}
output "conn2_t2_cgw_inside_address" {
  description = "GCP-side BGP IP (169.254.x.x) for conn2/tunnel2 — append /30 when passing to infra/gcp."
  value       = aws_vpn_connection.conn2.tunnel2_cgw_inside_address
}
output "conn2_t2_vgw_inside_address" {
  description = "AWS/TGW-side BGP peer IP for conn2/tunnel2."
  value       = aws_vpn_connection.conn2.tunnel2_vgw_inside_address
}

output "transit_gateway_id" {
  description = "ID of the Transit Gateway — useful for additional VPC attachments."
  value       = aws_ec2_transit_gateway.main.id
}
