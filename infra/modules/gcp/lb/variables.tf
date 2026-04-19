variable "project_id" { description = "The GCP Project ID" }
variable "env_name"   { description = "Environment name" }

variable "domain" {
  description = "Fully-qualified domain name (e.g. app.example.com). Empty = HTTP-only mode, no TLS."
  type        = string
  default     = ""
}

variable "dns_zone_dns_name" {
  description = "Cloud DNS zone dns_name (e.g. 'example.com.'). Empty = skip DNS zone creation."
  type        = string
  default     = ""
}

variable "frontend_neg_ids" {
  description = "Self-links of NEGs for the frontend service. Populate after workload deploy via: gcloud compute network-endpoint-groups list --filter='name:frontend-neg' --format='value(selfLink)'"
  type        = list(string)
  default     = []
}

variable "payment_neg_ids" {
  description = "Self-links of NEGs for the payment service. Populate after workload deploy via: gcloud compute network-endpoint-groups list --filter='name:payment-neg' --format='value(selfLink)'"
  type        = list(string)
  default     = []
}

variable "iap_client_id" {
  description = "OAuth 2.0 client ID for IAP on the frontend backend. Empty = IAP disabled. Create at: APIs & Services → Credentials."
  type        = string
  default     = ""
}

variable "iap_client_secret" {
  description = "OAuth 2.0 client secret for IAP."
  type        = string
  default     = ""
  sensitive   = true
}

variable "iap_members" {
  description = "IAM members granted roles/iap.httpsResourceAccessor (e.g. ['user:you@example.com'])."
  type        = list(string)
  default     = []
}
