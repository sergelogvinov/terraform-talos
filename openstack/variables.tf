
data "terraform_remote_state" "prepare" {
  backend = "local"
  config = {
    path = "${path.module}/prepare/terraform.tfstate"
  }
}

locals {
  regions          = data.terraform_remote_state.prepare.outputs.regions
  network_external = data.terraform_remote_state.prepare.outputs.network_external

  network         = data.terraform_remote_state.prepare.outputs.network
  network_public  = data.terraform_remote_state.prepare.outputs.network_public
  network_private = data.terraform_remote_state.prepare.outputs.network_private
  network_subnets = { for zone in local.regions : zone => [local.network_public[zone].cidr, local.network_private[zone].cidr] }
}

variable "kubernetes" {
  type = map(string)
  default = {
    podSubnets     = "10.32.0.0/12,fd40:10:32::/102"
    serviceSubnets = "10.200.0.0/22,fd40:10:200::/112"
    domain         = "cluster.local"
    apiDomain      = "api.cluster.local"
    clusterName    = "talos-k8s-openstack"
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
    "GRA7" = {
      count         = 0,
      instance_type = "d2-2",
    },
    "GRA9" = {
      count         = 0,
      instance_type = "d2-2",
    },
  }
}

variable "instances" {
  description = "Map of region's properties"
  type        = map(any)
  default = {
    "GRA9" = {
      web_count            = 0,
      web_instance_type    = "d2-2",
      worker_count         = 0,
      worker_instance_type = "d2-2",
    },
  }
}

variable "whitelist_admins" {
  description = "Whitelist for administrators"
  default     = ["0.0.0.0/0", "::/0"]
}

variable "whitelist_web" {
  description = "Whitelist for web (default Cloudflare network)"
  default = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "172.64.0.0/13",
    "131.0.72.0/22",
    "104.16.0.0/13",
    "104.24.0.0/14",
  ]
}
