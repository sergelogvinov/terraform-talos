
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
}

variable "proxmox_storage" {
  description = "Proxmox storage name"
  type        = string
}

variable "proxmox_bridge" {
  description = "Proxmox bridge name"
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

variable "worker" {
  description = "Property of worker"
  type        = map(any)
  default = {
    count = 0,
  }
}
