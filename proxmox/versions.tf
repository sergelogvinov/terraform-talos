terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9.14"
    }
    # proxmox = {
    #   source  = "bpg/proxmox"
    #   version = "~> 0.35.1"
    # }
  }
  required_version = ">= 1.0"
}
