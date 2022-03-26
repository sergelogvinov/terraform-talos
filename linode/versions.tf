
terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 1.26.3"
    }
  }
  required_version = ">= 1.0"
}
