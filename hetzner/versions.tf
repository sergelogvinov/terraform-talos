terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.38.2"
    }
  }
  required_version = ">= 1.2"
}
