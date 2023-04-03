terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9.14"
    }
    # proxmox = {
    #   source  = "bpg/proxmox"
    #   version = "0.17.0-rc1"
    # }
  }
  required_version = ">= 1.0"
}
