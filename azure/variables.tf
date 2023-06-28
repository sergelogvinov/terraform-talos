
variable "controlplane_role_definition" {
  default = ["kubernetes-ccm", "kubernetes-csi", "kubernetes-node-autoscaler"]
}

variable "gallery_name" {
  default = ""
}

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

  network              = data.terraform_remote_state.prepare.outputs.network
  network_controlplane = data.terraform_remote_state.prepare.outputs.network_controlplane
  network_public       = data.terraform_remote_state.prepare.outputs.network_public
  network_private      = data.terraform_remote_state.prepare.outputs.network_private
  network_secgroup     = data.terraform_remote_state.prepare.outputs.secgroups
}

variable "arch" {
  description = "The Talos architecture list"
  type        = list(string)
  default     = ["x64", "Arm64"]
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
      count = 0,
      type  = "Standard_B2ms",
    },
    "ukwest" = {
      count = 0,
      type  = "Standard_B2ms",
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

variable "acr" {
  type = map(string)
  default = {
    acrRepo     = ""
    acrUsername = ""
    acrPassword = ""
  }
}

variable "zones" {
  description = "The Azure zones"
  type        = list(string)
  default     = ["1", "3"]
}

variable "ssh_public_key" {
  description = "The SSH-RSA public key, ssh-keygen -t rsa -b 2048 -f ~/.ssh/terraform -C 'terraform'"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBx2qCSLlZ03TYqHm88pXZPyqZ3fvR1p2jWvsLt3uX+mBMr6B8S4vkX3oEBv43IEgi1bkIrdjJ50QvXNWS6fSOo6G0wZ0FHRCan3t4Kq2U+qoWkDsb5K0Kdgd9DZuaNM9412J2dWldYK7iD3hhQ3wh/E1gPlqrYb2AsPAarK+VA59n63QCDrpmGCW/Pki69e8Mt7HH/A1uw+4wvlrtaytrx6C3Y3/mQfBoas4XJliWHeTgEKeVdIzlOf9XrDnZ85pmvmQbFAtRtaRlfwCHMksVEwunYbg1RPrvQ8/YsSv6sFHwwvqjrJ7hdJcaa3afS3rUyAy7vkO0OXm4KdOEgE8X terraform"
}

variable "instances" {
  description = "Map of region's properties"
  type        = map(any)
  default = {
    "uksouth" = {
      web_count    = 0,
      web_type     = "Standard_B2s",
      worker_count = 0,
      worker_type  = "Standard_B4ms", # B4ms E2as_v4
      db_count     = 0,
      db_type      = "Standard_B4ms",
    },
    "ukwest" = {
      web_count    = 0,
      web_type     = "Standard_B2s",
      worker_count = 0,
      worker_type  = "Standard_B4ms", # B4ms E2as_v4
      db_count     = 0,
      db_type      = "Standard_B4ms",
    },
  }
}
