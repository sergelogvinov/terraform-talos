
variable "project" {
  description = "The project ID to host"
}

variable "cluster_name" {
  description = "The cluster name"
}

variable "region" {
  description = "The region to host"
}

variable "zone" {
  description = "The zone to host"
}

variable "name" {
  description = "The host name"
}

variable "network" {
  description = "The VPC network created to host"
}

variable "subnetwork" {
  description = "The VPC subnetwork created to host"
  default     = "core"
}

variable "network_cidr" {
  description = "Local subnet rfc1918"
  default     = "172.16.0.0/16"
}

variable "tags" {
  description = "Tags of resources"
  type        = list(string)
  default = [
    "develop"
  ]
}

variable "kubernetes" {
  type = map(string)
  default = {
    podSubnets     = "10.32.0.0/12"
    serviceSubnets = "10.200.0.0/22"
    domain         = "cluster.local"
    cluster_name   = "malta"
    tokenmachine   = ""
    token          = ""
    ca             = ""
  }
  sensitive = true
}

variable "instance_template" {
  description = "Instance template"
}

variable "controlplane" {
  description = "Map of controlplane params"
  type        = map(any)
  default = {
    count = 0,
    type  = "e2-small",
  }
}
