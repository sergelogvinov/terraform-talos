
variable "proxmox_domain" {
  description = "Proxmox host"
  type        = string
  default     = "example.com"
}

variable "proxmox_host" {
  description = "Proxmox host"
  type        = string
  default     = "192.168.1.1"
}

variable "proxmox_nodename" {
  description = "Proxmox node name"
  type        = string
}

variable "proxmox_image" {
  description = "Proxmox source image name"
  type        = string
  default     = "talos"
}

variable "proxmox_storage" {
  description = "Proxmox storage name"
  type        = string
}

variable "proxmox_token_id" {
  description = "Proxmox token id"
  type        = string
}

variable "proxmox_token_secret" {
  description = "Proxmox token secret"
  type        = string
}

variable "region" {
  description = "Proxmox host"
  type        = string
  default     = "nova"
}

variable "kubernetes" {
  type = map(string)
  default = {
    podSubnets     = "10.32.0.0/12,fd40:10:32::/102"
    serviceSubnets = "10.200.0.0/22,fd40:10:200::/112"
    domain         = "cluster.local"
    apiDomain      = "api.cluster.local"
    clusterName    = "talos-k8s-proxmox"
    tokenMachine   = ""
    caMachine      = ""
    token          = ""
    ca             = ""
  }
  sensitive = true
}

variable "vpc_main_cidr" {
  description = "Local proxmox subnet"
  type        = string
  default     = "192.168.10.0/24"
}

variable "controlplane" {
  description = "Property of controlplane"
  type        = map(any)
  default = {
    count = 0,
  }
}

variable "instances" {
  description = "Map of region's properties"
  type        = map(any)
  default = {
    "node1" = {
      web_id       = 1000
      web_count    = 0,
      web_cpu      = 2,
      web_mem      = 4096,
      worker_id    = 1050
      worker_count = 0,
      worker_cpu   = 2,
      worker_mem   = 4096,
    },
    "node2" = {
      web_id       = 2000
      web_count    = 0,
      web_cpu      = 2,
      web_mem      = 4096,
      worker_id    = 2050
      worker_count = 0,
      worker_cpu   = 2,
      worker_mem   = 4096,
    }
    "node3" = {
      web_id       = 3000
      web_count    = 0,
      web_cpu      = 2,
      web_mem      = 4096,
      worker_id    = 3050
      worker_count = 0,
      worker_cpu   = 2,
      worker_mem   = 4096,
    }
  }
}
