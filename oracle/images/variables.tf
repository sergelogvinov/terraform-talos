
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
  default = "~/.oci/oci_main_terraform.pem"
}

data "terraform_remote_state" "init" {
  backend = "local"
  config = {
    path = "${path.module}/../prepare/terraform.tfstate"
  }
}

locals {
  region = data.terraform_remote_state.init.outputs.region
  tags   = data.terraform_remote_state.init.outputs.tags
}

variable "release" {
  description = "The image name"
  type        = string
  default     = "1.6.7"
}

variable "arch" {
  description = "The Talos architecture list"
  type        = list(string)
  default     = ["amd64", "arm64"]
}
