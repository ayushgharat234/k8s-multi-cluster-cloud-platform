project_id    = "HOST_PROJECT_ID"
region        = "us-central1"
subnet_cidr   = "10.0.0.0/20"  # Nodes (10.0.0.0 - 10.0.15.255)
pods_cidr     = "10.4.0.0/14"  # Pods
services_cidr = "10.8.0.0/20"  # Services

# Add your Service Projects here (when you have them)
service_project_ids     = ["service-project-1", "service-project-2"]
service_project_numbers = ["12345678901", "12345678902"]