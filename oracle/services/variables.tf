
variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
  default     = "ocid1.compartment.oc1.."
}
variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
  default     = "ocid1.tenancy.oc1.."
}
variable "user_ocid" {}
variable "fingerprint" {}
variable "key_file" {
  default = "~/.oci/oci_production_terraform.pem"
}

data "terraform_remote_state" "prepare" {
  backend = "local"
  config = {
    path = "${path.module}/../prepare/terraform.tfstate"
  }
}

locals {
  project = data.terraform_remote_state.prepare.outputs.project
  region  = data.terraform_remote_state.prepare.outputs.region
  tags    = data.terraform_remote_state.prepare.outputs.tags
}

variable "repos" {
  default = [
    "kubelet",
  ]
}
