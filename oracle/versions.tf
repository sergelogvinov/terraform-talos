
terraform {
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "4.102.0"
    }
  }
  required_version = ">= 1.2"
}
