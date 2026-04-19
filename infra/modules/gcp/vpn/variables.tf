variable "env_name"     { type = string }
variable "vpc_id"       { type = string }
variable "region"       { type = string }
variable "pod_cidr"     { type = string }
variable "service_cidr" { type = string }

variable "aws_tunnel1_address" {
  type    = string
  default = ""
}
variable "aws_tunnel1_psk" {
  type      = string
  default   = ""
  sensitive = true
}
variable "aws_tunnel1_cgw_inside_address" {
  type    = string
  default = ""
}
variable "aws_tunnel1_vgw_inside_address" {
  type    = string
  default = ""
}
variable "aws_tunnel2_address" {
  type    = string
  default = ""
}
variable "aws_tunnel2_psk" {
  type      = string
  default   = ""
  sensitive = true
}
variable "aws_tunnel2_cgw_inside_address" {
  type    = string
  default = ""
}
variable "aws_tunnel2_vgw_inside_address" {
  type    = string
  default = ""
}
