terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.7.4"
    }
  }
  required_version = ">= 1.0"
}
