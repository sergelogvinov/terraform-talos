terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.86.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
  }
  required_version = ">= 1.0"
}
