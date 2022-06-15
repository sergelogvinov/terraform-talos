
variable "clouds" {
  type        = string
  description = "The config section in clouds.yaml"
  default     = "openstack"
}

variable "project_id" {
  type        = string
  description = "The project_id of the openstack"
  default     = ""
}

variable "regions" {
  type        = list(string)
  description = "The id of the openstack region"
  default     = ["GRA7", "GRA9"]
}

variable "network_name_external" {
  type    = string
  default = "Ext-Net"
}

variable "network_name" {
  type    = string
  default = "main"
}

variable "network_cidr" {
  description = "Local subnet rfc1918"
  type        = string
  default     = "172.16.0.0/16"
}

variable "whitelist_admins" {
  description = "Whitelist for administrators"
  default     = ["0.0.0.0/0", "::/0"]
}

variable "network_shift" {
  description = "Network number shift"
  type        = number
  default     = 32
}

variable "capabilities" {
  type = map(any)
  default = {
    "GRA7" = {
      gateway      = false
      peering      = false
      peering_type = "d2-2"
    },
    "GRA9" = {
      gateway      = false
      peering      = false
      peering_type = "d2-2"
    },
  }
}
