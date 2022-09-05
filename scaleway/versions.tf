
terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.2.9"
    }
  }
  required_version = ">= 1.0"
}
