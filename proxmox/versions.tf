terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.3"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
  }
  required_version = ">= 1.0"
}
