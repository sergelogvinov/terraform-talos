terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.26.2"
    }
    # talos = {
    #   source  = "terraform.borancar.com/borancar/talos"
    #   version = ">= 0.1"
    # }
  }
  required_version = ">= 0.15"
}
