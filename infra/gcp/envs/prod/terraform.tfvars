project_id            = "HOST_PROJECT_ID"
management_project_id = "MGMT_SERVICE_PROJECT_ID"
tenant_1_project_id   = "TENANT_1_SERVICE_PROJECT_ID"
tenant_2_project_id   = "TENANT_2_SERVICE_PROJECT_ID"
region                = "us-central1"

subnet_cidr   = "10.0.0.0/20"  # Nodes (10.0.0.0 - 10.0.15.255)
pods_cidr     = "10.4.0.0/14"  # Pods
services_cidr = "10.8.0.0/20"  # Services

# Add ALL your Service Projects here (Mgmt + Tenants)
# This list whitelists them in the Host Network
service_project_ids     = ["mgmt-project", "tenant-1-project", "tenant-2-project"]
service_project_numbers = ["11111111111", "22222222222", "33333333333"]