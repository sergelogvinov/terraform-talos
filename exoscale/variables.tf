
variable "exoscale_api_key" { type = string }
variable "exoscale_api_secret" { type = string }

data "terraform_remote_state" "prepare" {
  backend = "local"
  config = {
    path = "${path.module}/prepare/terraform.tfstate"
  }
}

locals {
  project = data.terraform_remote_state.prepare.outputs.project
  regions = data.terraform_remote_state.prepare.outputs.regions

  network          = data.terraform_remote_state.prepare.outputs.network
  network_secgroup = data.terraform_remote_state.prepare.outputs.secgroups
}

variable "tags" {
  description = "Tags of resources"
  type        = map(string)
  default = {
    "env" = "develop"
  }
}

variable "controlplane" {
  description = "Controlplane config"
  type        = map(any)
  default = {
    "de-fra-1" = {
      count = 0,
      type  = "standard.small",
    },
    "de-muc-1" = {
      count = 0,
      type  = "standard.tiny",
    },
  }
}

variable "instances" {
  description = "Map of region's properties"
  type        = map(any)
  default = {
    "de-fra-1" = {
      web_count    = 0,
      web_type     = "standard.tiny",
      worker_count = 0,
      worker_type  = "standard.tiny",
    },
    "de-muc-1" = {
      web_count    = 0,
      web_type     = "standard.tiny",
      worker_count = 0,
      worker_type  = "standard.tiny",
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
    clusterName    = "talos-k8s-exoscale"
  }
  sensitive = true
}
