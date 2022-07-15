terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.34.3"
    }
  }
  required_version = ">= 1.2"
}
