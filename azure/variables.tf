
data "terraform_remote_state" "prepare" {
  backend = "local"
  config = {
    path = "${path.module}/prepare/terraform.tfstate"
  }
}

locals {
  subscription_id = data.terraform_remote_state.prepare.outputs.subscription
  project         = data.terraform_remote_state.prepare.outputs.project
  regions         = data.terraform_remote_state.prepare.outputs.regions
  resource_group  = data.terraform_remote_state.prepare.outputs.resource_group

  network_public   = data.terraform_remote_state.prepare.outputs.network_public
  network_private  = data.terraform_remote_state.prepare.outputs.network_private
  network_secgroup = data.terraform_remote_state.prepare.outputs.secgroups
}

variable "tags" {
  description = "Tags of resources"
  type        = map(string)
  default = {
    environment = "Develop"
  }
}

variable "controlplane" {
  description = "Controlplane config"
  type        = map(any)
  default = {
    "uksouth" = {
      count         = 0,
      instance_type = "Standard_B2s",
    },
    "ukwest" = {
      count         = 0,
      instance_type = "Standard_B2s",
    },
  }
}

variable "kubernetes" {
  type = map(string)
  default = {
    podSubnets     = "10.32.0.0/12,fd40:10:32::/102"
    serviceSubnets = "10.200.0.0/22,fd40:10:200::/112"
    domain         = "cluster.local"
    apiDomain      = "api.cluster.local"
    clusterName    = "talos-k8s-azure"
    clusterID      = ""
    clusterSecret  = ""
    tokenMachine   = ""
    caMachine      = ""
    token          = ""
    ca             = ""
  }
  sensitive = true
}

variable "instances" {
  description = "Map of region's properties"
  type        = map(any)
  default = {
    "uksouth" = {
      web_count            = 0,
      web_instance_type    = "Standard_B2s",
      worker_count         = 0,
      worker_instance_type = "Standard_B4ms", # B4ms E2as_v4
    },
    "ukwest" = {
      web_count            = 0,
      web_instance_type    = "Standard_B2s",
      worker_count         = 0,
      worker_instance_type = "Standard_B4ms", # B4ms E2as_v4
    },
  }
}
