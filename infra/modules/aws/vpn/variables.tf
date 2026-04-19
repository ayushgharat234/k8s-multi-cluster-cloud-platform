variable "env_name"                  { type = string }
variable "vpc_id"                     { type = string }
variable "gcp_vpn_gateway_ip"         { type = string }
variable "private_route_table_ids"    { type = list(string) }
variable "cluster_security_group_id"  { type = string }
variable "gcp_cidr_ranges" {
  type    = list(string)
  default = ["10.16.0.0/20", "10.17.0.0/16", "10.18.0.0/20"]
}
