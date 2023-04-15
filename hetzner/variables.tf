
variable "hcloud_token" {
  description = "The hezner cloud token (export TF_VAR_hcloud_token=$TOKEN)"
  type        = string
  sensitive   = true
}

variable "robot_user" {
  description = "The hezner cloud token (export TF_VAR_robot_user=$USER)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "robot_password" {
  description = "The hezner cloud token (export TF_VAR_robot_password=$PASSWORD)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "regions" {
  description = "The id of the hezner region (oreder is important)"
  type        = list(string)
  default     = ["nbg1", "fsn1", "hel1"]
}

variable "kubernetes" {
  type = map(string)
  default = {
    podSubnets     = "10.32.0.0/12,fd40:10:32::/102"
    serviceSubnets = "10.200.0.0/22,fd40:10:200::/112"
    apiDomain      = "api.cluster.local"
    domain         = "cluster.local"
    clusterName    = "talos-k8s-hetzner"
    tokenMachine   = ""
    caMachine      = ""
    token          = ""
    ca             = ""
  }
}

variable "vpc_main_cidr" {
  description = "Local subnet rfc1918"
  type        = string
  default     = "172.16.0.0/16"
}

variable "vpc_main_zone" {
  description = "Network zone"
  type        = string
  default     = "eu-central"
}

variable "vpc_vswitch_id" {
  description = "vSwitch id"
  type        = number
  default     = 0
}

variable "controlplane" {
  description = "Controlplane scheme"
  type        = map(any)
  default = {
    "all" = {
      type_lb = "" # lb11, if "" use floating-ip
    },

    "nbg1" = {
      count = 0,
      type  = "cpx11",
    },
    "fsn1" = {
      count = 0,
      type  = "cpx11",
    },
    "hel1" = {
      count = 0,
      type  = "cax11",
    }
  }
}

variable "instances" {
  description = "Map of region's properties"
  type        = map(any)
  default = {
    "nbg1" = {
      web_count    = 0,
      web_type     = "cx11",
      worker_count = 0,
      worker_type  = "cx11",
    },
    "fsn1" = {
      web_count    = 0,
      web_type     = "cx11",
      worker_count = 0,
      worker_type  = "cx11",
    }
    "hel1" = {
      web_count    = 0,
      web_type     = "cx11",
      worker_count = 0,
      worker_type  = "cx11",
    }
  }
}

variable "tags" {
  description = "Tags of resources"
  type        = map(string)
  default = {
    environment = "Develop"
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
