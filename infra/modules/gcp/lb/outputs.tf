output "global_ip" {
  description = "Static global IP — access the app at http://<ip> (HTTP mode) or https://<domain> (TLS mode)."
  value       = google_compute_global_address.default.address
}

output "dns_name_servers" {
  description = "Cloud DNS name servers (only populated when dns_zone_dns_name is set)."
  value       = var.dns_zone_dns_name != "" ? google_dns_managed_zone.default[0].name_servers : []
}

output "cert_validation_cname" {
  description = "CNAME for Certificate Manager domain validation (only populated when domain is set)."
  value = var.domain != "" ? {
    name  = google_certificate_manager_dns_authorization.default[0].dns_resource_record[0].name
    type  = google_certificate_manager_dns_authorization.default[0].dns_resource_record[0].type
    value = google_certificate_manager_dns_authorization.default[0].dns_resource_record[0].data
  } : null
}

output "frontend_backend_service_id" {
  value = google_compute_backend_service.frontend.id
}
