variable "project_id" {}
variable "region" {}
variable "subnet_cidr" {}
variable "pods_cidr" {}
variable "services_cidr" {}

variable "service_project_ids" {
  type    = list(string)
  default = []
}

variable "service_project_numbers" {
  type    = list(string)
  default = []
}