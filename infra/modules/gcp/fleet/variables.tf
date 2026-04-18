variable "project_id" { description = "GCP Project ID" }

variable "clusters" {
  description = "Map of clusters to register in the fleet."
  type = map(object({
    id = string
  }))
}
