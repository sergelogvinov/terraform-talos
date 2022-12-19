terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.36.1"
    }
  }
  required_version = ">= 1.2"
}
