
variable "hcloud_token" {
  description = "The hezner cloud token (export TF_VAR_hcloud_token=$TOKEN)"
  type        = string
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
    podSubnets     = "10.32.0.0/12"
    serviceSubnets = "10.200.0.0/22"
    domain         = "cluster.local"
    cluster_name   = "talos-k8s-hezner"
    tokenmachine   = "4g8t1y.u3xw5r11fzyfuj8y"
    token          = "wq93rz.dsvn0aw5erdwp78f"
    ca             = ""
  }
}

variable "vpc_main_cidr" {
  description = "Local subnet rfc1918"
  type        = string
  default     = "172.16.0.0/16"
}

variable "vpc_vswitch_id" {
  description = "vSwitch id"
  type        = number
  default     = 0
}

variable "controlplane" {
  description = "Count of controlplanes"
  type        = map(any)
  default = {
    count = 1,
    type  = "cx11"
  }
}

variable "instances" {
  description = "Map of region's properties"
  type        = map(any)
  default = {
    "nbg1" = {
      web_count            = 0,
      web_instance_type    = "cx11",
      worker_count         = 0,
      worker_instance_type = "cx11",
    },
    "fsn1" = {
      web_count            = 0,
      web_instance_type    = "cx11",
      worker_count         = 0,
      worker_instance_type = "cx11",
    }
    "hel1" = {
      web_count            = 1,
      web_instance_type    = "cx11",
      worker_count         = 1,
      worker_instance_type = "cx11",
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
  default = ["0.0.0.0/0", "::/0"]
}

# variable "robot_servers" {
#   type = list(object({
#     name         = string
#     ipv4_address = string
#     ipv6_address = string
#     zone         = string
#     location     = string
#     params       = string
#   }))

#   default = []
# }

# variable "hosts" {
#   type = list(object({
#     name         = string
#     ipv4_address = string
#     ipv6_address = string
#   }))

#   default = [
#     {
#       name         = "api.local"
#       ipv4_address = "123"
#       ipv6_address = ""
#     },
#   ]
# }
