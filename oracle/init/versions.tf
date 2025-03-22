
terraform {
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "6.25.0"
    }
  }
  required_version = ">= 1.2"
}
