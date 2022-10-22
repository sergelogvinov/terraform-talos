
variable "exoscale_api_key" { type = string }
variable "exoscale_api_secret" { type = string }

variable "project" {
  type    = string
  default = "main"
}

variable "regions" {
  description = "The region name list"
  type        = list(string)
  default     = ["de-fra-1", "de-muc-1"]
}

variable "tags" {
  description = "Defined Tags of resources"
  type        = map(string)
  default = {
    "env" = "develop"
  }
}

variable "network_name" {
  type    = string
  default = "main"
}

variable "network_cidr" {
  description = "Local subnet rfc1918/ULA"
  type        = string
  default     = "172.16.0.0/16"
}

variable "network_shift" {
  description = "Network number shift"
  type        = number
  default     = 34
}

variable "whitelist_admin" {
  default = ["0.0.0.0/0"]
}

variable "whitelist_web" {
  default = ["0.0.0.0/0"]
}

variable "capabilities" {
  type = map(any)
  default = {
    "de-fra-1" = {
      network_lb        = false,
      network_gw_enable = false,
      network_gw_type   = "standard.micro",
    },
    "de-muc-1" = {
      network_lb        = false,
      network_gw_enable = false,
      network_gw_type   = "standard.micro",
    },
  }
}
