
variable "compartment_ocid" {}
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "key_file" {
  default = "~/.oci/oci_public.pem"
}

variable "project" {
  type    = string
  default = "main"
}

variable "region" {
  description = "the OCI region where resources will be created"
  type        = string
  default     = null
}

variable "tags" {
  description = "Defined Tags of resources"
  type        = map(string)
  default = {
    "Kubernetes.Environment" = "Develop"
  }
}

data "terraform_remote_state" "prepare" {
  backend = "local"
  config = {
    path = "${path.module}/prepare/terraform.tfstate"
  }
}

locals {
  project    = data.terraform_remote_state.prepare.outputs.project
  zones      = data.terraform_remote_state.prepare.outputs.zones
  zone_count = length(local.zones)

  dns_zone_id = data.terraform_remote_state.prepare.outputs.dns_zone_id

  network_lb      = data.terraform_remote_state.prepare.outputs.network_lb
  network_public  = data.terraform_remote_state.prepare.outputs.network_public
  network_private = data.terraform_remote_state.prepare.outputs.network_private

  nsg_contolplane_lb = data.terraform_remote_state.prepare.outputs.nsg_contolplane_lb
  nsg_contolplane    = data.terraform_remote_state.prepare.outputs.nsg_contolplane
  nsg_web            = data.terraform_remote_state.prepare.outputs.nsg_web
  nsg_worker         = data.terraform_remote_state.prepare.outputs.nsg_worker
  nsg_cilium         = data.terraform_remote_state.prepare.outputs.nsg_cilium
  nsg_talos          = data.terraform_remote_state.prepare.outputs.nsg_talos
}

variable "kubernetes" {
  type = map(string)
  default = {
    podSubnets     = "10.32.0.0/12,fd40:10:32::/102"
    serviceSubnets = "10.200.0.0/22,fd40:10:200::/112",
    domain         = "cluster.local"
    apiDomain      = "api.cluster.local"
    clusterName    = "talos-k8s-oracle"
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
  description = "Property of controlplane"
  type        = map(any)
  default = {
    count = 0,
    type  = "VM.Standard.E4.Flex"
    ocpus = 1
    memgb = 3
  }
}

variable "instances" {
  description = "Map of region's properties"
  type        = map(any)
  default = {
    "jNdv:eu-amsterdam-1-AD-1" = {
      web_count             = 0,
      web_instance_shape    = "VM.Standard.E2.1.Micro",
      web_instance_ocpus    = 1,
      web_instance_memgb    = 1,
      worker_count          = 0,
      worker_instance_shape = "VM.Standard.E2.1.Micro",
      worker_instance_ocpus = 1,
      worker_instance_memgb = 1,
    },
  }
}
