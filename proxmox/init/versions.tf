terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.18.2"
    }
  }
  required_version = ">= 1.0"
}
