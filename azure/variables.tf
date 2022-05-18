
data "terraform_remote_state" "prepare" {
  backend = "local"
  config = {
    path = "${path.module}/prepare/terraform.tfstate"
  }
}

locals {
  subscription_id = data.terraform_remote_state.prepare.outputs.subscription
  regions         = data.terraform_remote_state.prepare.outputs.regions
  resource_group  = data.terraform_remote_state.prepare.outputs.resource_group

  network_public  = data.terraform_remote_state.prepare.outputs.network_public
  network_private = data.terraform_remote_state.prepare.outputs.network_private
}

variable "controlplane" {
  description = "Controlplane config"
  type        = map(any)
  default = {
    "uksouth" = {
      count         = 0,
      instance_type = "Standard_D2as_v4",
    },
    "ukwest" = {
      count         = 0,
      instance_type = "Standard_B2s",
    },
  }
}

variable "tags" {
  description = "Tags of resources"
  type        = map(string)
  default = {
    environment = "Develop"
  }
}
