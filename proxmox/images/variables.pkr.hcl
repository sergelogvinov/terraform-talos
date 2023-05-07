
variable "proxmox_host" {
  type    = string
}

variable "proxmox_username" {
  type    = string
}

variable "proxmox_token" {
  type    = string
}

variable "proxmox_nodename" {
  type    = string
}

variable "proxmox_storage" {
  type    = string
}

variable "proxmox_storage_type" {
  type    = string
}

variable "talos_version" {
  type    = string
  default = "v1.4.1"
}

locals {
  image = "https://github.com/talos-systems/talos/releases/download/${var.talos_version}/nocloud-amd64.raw.xz"
}
