variable "project_id" { description = "The GCP Project ID" }
variable "env_name"   { description = "Environment name" }

variable "domain" {
  description = "Fully-qualified domain name for the Google-managed SSL certificate."
  type        = string
}

variable "neg_ids" {
  description = "List of Network Endpoint Group self-links from GKE services."
  type        = list(string)
  default     = []
}
