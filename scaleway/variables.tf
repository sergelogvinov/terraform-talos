
variable "scaleway_access" {
  description = "The scaleway access key (export TF_VAR_scaleway_access=$access_key)"
  type        = string
  sensitive   = true
}

variable "scaleway_secret" {
  description = "The scaleway secret key (export TF_VAR_scaleway_secret=$secret_key)"
  type        = string
  sensitive   = true
}

variable "scaleway_project_id" {
  description = "The scaleway secret key (export TF_VAR_scaleway_project_id=$project_id)"
  type        = string
  sensitive   = true
}

variable "regions" {
  description = "The id of the scaleway region (oreder is important)"
  type        = list(string)
  default     = ["fr-par-1", "fr-par-2", "nl-ams-1"]
}

variable "arch" {
  description = "The Talos architecture list"
  type        = list(string)
  default     = ["amd64", "arm64"]
}

variable "kubernetes" {
  type = map(string)
  default = {
    podSubnets     = "10.32.0.0/12,fd40:10:32::/102"
    serviceSubnets = "10.200.0.0/22,fd40:10:200::/112"
    domain         = "cluster.local"
    apiDomain      = "api.cluster.local"
    clusterName    = "talos-k8s-scaleway"
    clusterID      = ""
    clusterSecret  = ""
    tokenMachine   = ""
    caMachine      = ""
    token          = ""
    ca             = ""
  }
  sensitive = true
}

variable "vpc_main_cidr" {
  description = "Local subnet rfc1918"
  type        = string
  default     = "172.16.0.0/16"
}

variable "controlplane" {
  description = "Property of controlplane"
  type        = map(any)
  default = {
    count   = 1,
    type    = "COPARM1-2C-8G" # "DEV1-L",
    type_lb = ""              # "LB-S"
  }
}

variable "instances" {
  description = "Map of instance properties"
  type        = map(any)
  default = {
    "all" = {
      version = "v1.30.2"
    },
    # web_count    = 0,
    # web_type     = "DEV1-L",
    # worker_count = 0,
    # worker_type  = "DEV1-L",
  }
}

variable "tags" {
  description = "Tags of resources"
  type        = list(string)
  default     = ["Develop"]
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
