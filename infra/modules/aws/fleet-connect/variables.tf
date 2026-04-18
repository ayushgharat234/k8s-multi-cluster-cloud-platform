variable "project_id"     { description = "GCP Project ID" }
variable "project_number" { description = "GCP Project Number (numeric, used in fleet project reference)" }
variable "env_name"         { description = "Environment Name" }
variable "cluster_name"     { description = "EKS Cluster Name" }
variable "gcp_location"     { description = "Administrative GCP Region" }
variable "platform_version" { description = "GKE Attached Cluster Version" }
variable "eks_oidc_url"     { description = "EKS OIDC Provider URL" }
