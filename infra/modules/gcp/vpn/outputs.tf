output "vpn_gateway_ip" {
  description = "External IP of the GCP HA VPN Gateway interface 0 — pass this to the AWS stack as gcp_vpn_gateway_ip."
  value       = google_compute_ha_vpn_gateway.main.vpn_interfaces[0].ip_address
}

output "vpn_gateway_ip_1" {
  description = "External IP of the GCP HA VPN Gateway interface 1."
  value       = google_compute_ha_vpn_gateway.main.vpn_interfaces[1].ip_address
}
