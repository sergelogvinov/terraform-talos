
terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.8.0"
    }
  }
  required_version = ">= 1.0"
}
