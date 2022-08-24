variable "ssh_public_keys" {
  type        = map(string)
  description = "The SSH keys used to access the server."
}

variable "region" {
  type        = string
  description = "The server's desired region. Valid regions at https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm."
  default     = "us-ashburn-1"
}

variable "tenancy_ocid" {
  type        = string
  description = "OCID of your root tenancy."
}

variable "config_file_profile" {
  type        = string
  description = "The named config file profile."
  default     = "SEZF"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The vpc cidr block to use."
  default     = "10.1.0.0/16"
}

variable "domain" {
  type        = string
  description = "Website domain"
  default     = "bmlt.sezf.org"
}

variable "root_server_mysql_username" {
  type        = string
  description = "Root server mysql username"
  default     = "bmlt"
}

variable "root_server_mysql_password" {
  type        = string
  description = "Root server mysql password"
  default     = "bmlt"
}

variable "yap_mysql_username" {
  type        = string
  description = "Yap mysql username"
  default     = "yap"
}

variable "yap_mysql_password" {
  type        = string
  description = "Yap mysql password"
  default     = "yap"
}
