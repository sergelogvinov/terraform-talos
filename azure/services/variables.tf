
data "terraform_remote_state" "prepare" {
  backend = "local"
  config = {
    path = "${path.module}/../prepare/terraform.tfstate"
  }
}

locals {
  subscription_id = data.terraform_remote_state.prepare.outputs.subscription
  regions         = data.terraform_remote_state.prepare.outputs.regions
  resource_group  = data.terraform_remote_state.prepare.outputs.resource_group
}

variable "principal" {
  description = "principal id to have RW access the backet"
  type        = string
}

variable "tags" {
  description = "Tags of resources"
  type        = map(string)
  default = {
    environment = "Develop"
  }
}
