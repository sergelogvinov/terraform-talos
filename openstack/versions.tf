terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.45.0"
    }
  }
  required_version = ">= 1.0"
}
