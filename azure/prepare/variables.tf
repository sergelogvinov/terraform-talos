
variable "subscription_id" {
  description = "The subscription id"
  type        = string
}

variable "resource_group" {
  description = "The resource group name"
  type        = string
}

variable "regions" {
  description = "The region name list"
  type        = list(string)
  default     = ["uksouth", "ukwest"]

  validation {
    condition     = length(var.regions) == 2
    error_message = "The regions list must have only 2 zones."
  }
}

variable "tags" {
  description = "Tags to set on resources"
  type        = map(string)
  default = {
    environment = "Develop"
  }
}

variable "network_name" {
  type    = string
  default = "main"
}

variable "network_cidr" {
  description = "Local subnet rfc1918/ULA"
  type        = list(string)
  default     = ["172.16.0.0/16", "fd60:172:16::/56"]

  validation {
    condition     = length(var.network_cidr) == 2
    error_message = "The network_cidr is a list of IPv4/IPv6 cidr."
  }
}

variable "network_shift" {
  description = "Network number shift"
  type        = number
  default     = 34
}

variable "whitelist_admin" {
  default = ["*"]
}

variable "whitelist_web" {
  default = ["*"]
}

variable "capabilities" {
  type = map(any)
  default = {
    "uksouth" = {
      network_nat_enable = false,
      network_lb_type    = "Basic", # Standard
      network_gw_enable  = false,
      network_gw_type    = "Standard_B1s",

    },
    "ukwest" = {
      network_nat_enable = false,
      network_lb_type    = "Basic",
      network_gw_enable  = false,
      network_gw_type    = "Standard_B1s",
    },
  }
}
