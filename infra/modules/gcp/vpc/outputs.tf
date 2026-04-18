output "vpc_id" {
  description = "The ID of the VPC."
  value       = google_compute_network.vpc.id
}

output "subnet_id" {
  description = "The ID of the primary subnet."
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_name" {
  description = "The name of the primary subnet."
  value       = google_compute_subnetwork.subnet.name
}

output "pod_range_name" {
  description = "The name of the secondary pod range."
  value       = google_compute_subnetwork.subnet.secondary_ip_range[0].range_name
}

output "service_range_name" {
  description = "The name of the secondary service range."
  value       = google_compute_subnetwork.subnet.secondary_ip_range[1].range_name
}
