terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.43.1"
    }
  }
  required_version = ">= 1.0"
}
