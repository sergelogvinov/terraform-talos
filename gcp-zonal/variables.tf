
data "terraform_remote_state" "prepare" {
  backend = "local"
  config = {
    path = "${path.module}/prepare/terraform.tfstate"
  }
}

locals {
  project = data.terraform_remote_state.prepare.outputs.project
  region  = data.terraform_remote_state.prepare.outputs.region
  zones   = data.terraform_remote_state.prepare.outputs.zones

  cluster_name = data.terraform_remote_state.prepare.outputs.cluster_name

  network              = data.terraform_remote_state.prepare.outputs.network
  network_controlplane = data.terraform_remote_state.prepare.outputs.network_controlplane
  networks             = data.terraform_remote_state.prepare.outputs.networks
}

variable "kubernetes" {
  type = map(string)
  default = {
    podSubnets     = "10.32.0.0/12,fd40:10:32::/102"
    serviceSubnets = "10.200.0.0/22,fd40:10:200::/112"
    domain         = "cluster.local"
    apiDomain      = "api.cluster.local"
    clusterName    = "talos-k8s-gcp"
    clusterID      = ""
    clusterSecret  = ""
    tokenMachine   = ""
    caMachine      = ""
    token          = ""
    ca             = ""
  }
  sensitive = true
}

variable "controlplane" {
  description = "Controlplane config"
  type        = map(any)
  default = {
    "europe-north1-a" = {
      count = 0,
      type  = "e2-medium",
    },
    "europe-north1-b" = {
      count = 0,
      type  = "e2-medium",
    },
  }
}

variable "instances" {
  description = "Map of region's properties"
  type        = map(any)
  default = {
    "europe-north1-a" = {
      web_count    = 0,
      web_type     = "e2-small",
      worker_count = 0,
      worker_type  = "e2-small",
    },
    "europe-north1-b" = {
      web_count    = 0,
      web_type     = "e2-small",
      worker_count = 0,
      worker_type  = "e2-small",
    }
    "europe-north1-c" = {
      web_count    = 0,
      web_type     = "e2-small",
      worker_count = 0,
      worker_type  = "e2-small",
    }
  }
}

variable "tags" {
  description = "Tags of resources"
  type        = list(string)
  default = [
    "develop"
  ]
}
