variable "vnet_address" {
  type        = list(string)
  description = "CIDR Virtual Network"
}

variable "services" {
  description = "Services that we will be use"
}

variable "local_private_key_path" {
  description = "Local Private Key Path 'linuxkey.pem' "
  type        = string
}

variable "remote_user" {
  description = "Remote User in Virtual machines"
  type        = string
}

variable "remote_path" {
  description = "Remote Path in Virtual machines"
  type        = string
}
