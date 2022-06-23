
terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.2.2"
    }
  }
  required_version = ">= 1.0"
}
