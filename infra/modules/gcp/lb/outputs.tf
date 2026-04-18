output "global_ip" {
  description = "The static global IP address of the External Load Balancer."
  value       = google_compute_global_address.default.address
}
