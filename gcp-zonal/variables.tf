
variable "project_id" {
  description = "The project ID to host the cluster in"
}

variable "cluster_name" {
  description = "A default cluster name"
  default     = "talos"
}

variable "region" {
  description = "The region to host the cluster in"
}

variable "zones" {
  type        = list(string)
  description = "The zone to host the cluster in (required if is a zonal cluster)"
}

variable "kubernetes" {
  type = map(string)
  default = {
    podSubnets     = "10.32.0.0/12"
    serviceSubnets = "10.200.0.0/22"
    domain         = "cluster.local"
    cluster_name   = "talos-k8s-hezner"
    tokenmachine   = ""
    token          = ""
    ca             = ""
  }
  sensitive   = true
}

variable "network" {
  description = "The VPC network created to host the cluster in"
  default     = "production"
}

variable "network_cidr" {
  description = "Local subnet rfc1918"
  default     = "172.16.0.0/16"
}

variable "whitelist_web" {
  description = "Cloudflare subnets"
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

variable "whitelist_admin" {
  description = "Cloudflare subnets"
  default = [
    "0.0.0.0/0",
  ]
}

variable "tags" {
  description = "Tags of resources"
  type        = list(string)
  default = [
    "develop"
  ]
}

variable "controlplane" {
  description = "Count of controlplanes"
  type        = map(any)
  default = {
    count = 0,
    type  = "e2-small"
  }
}

variable "instances" {
  description = "Map of region's properties"
  type        = map(any)
  default = {
    "a" = {
      web_count            = 0,
      web_instance_type    = "e2-small",
      worker_count         = 0,
      worker_instance_type = "e2-small",
    },
    "b" = {
      web_count            = 0,
      web_instance_type    = "e2-small",
      worker_count         = 0,
      worker_instance_type = "e2-small",
    }
    "c" = {
      web_count            = 0,
      web_instance_type    = "e2-small",
      worker_count         = 0,
      worker_instance_type = "e2-small",
    }
    "all" = {
      web_count            = 0,
      web_instance_type    = "e2-small",
      worker_count         = 0,
      worker_instance_type = "e2-small",
    }
  }
}
