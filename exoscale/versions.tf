
terraform {
  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
      version = ">= 0.45.0"
    }
    talos = {
      source = "siderolabs/talos"
      # version = ">= 0.1.0"
    }
  }
  required_version = ">= 1.3"
}
