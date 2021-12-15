
variable "compartment_ocid" {}
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}

variable "project" {
  type    = string
  default = "main"
}

variable "region" {
  description = "the OCI region where resources will be created"
  type        = string
  default     = null
}

data "terraform_remote_state" "prepare" {
  backend = "local"
  config = {
    path = "${path.module}/prepare/terraform.tfstate"
  }
}

locals {
  project = data.terraform_remote_state.prepare.outputs.project

  nsg_contolplane_lb = data.terraform_remote_state.prepare.outputs.nsg_contolplane_lb
  network_lb         = data.terraform_remote_state.prepare.outputs.network_lb

  nsg_contolplane = data.terraform_remote_state.prepare.outputs.nsg_contolplane
  network_public  = data.terraform_remote_state.prepare.outputs.network_public
  network_private = data.terraform_remote_state.prepare.outputs.network_private
}
