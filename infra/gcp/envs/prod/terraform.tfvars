project_id            = "shared-vpc-project"
management_project_id = "mngt-cluster-1"
tenant_1_project_id   = "service-cluster-1"
tenant_2_project_id   = "service-cluster-2"
region                = "us-central1"

subnet_cidr   = "10.0.0.0/20"  # Nodes (10.0.0.0 - 10.0.15.255)
pods_cidr     = "10.4.0.0/14"  # Pods
services_cidr = "10.8.0.0/20"  # Services

# Add ALL your Service Projects here (Mgmt + Tenants)
# This list whitelists them in the Host Network
service_project_ids     = ["mngt-cluster-1", "service-cluster-1", "service-cluster-2"]
service_project_numbers = ["11111111111", "22222222222", "33333333333"] # TODO: Update with real numbers if needed