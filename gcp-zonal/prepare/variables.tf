
variable "project" {
  description = "The project ID to host the cluster in"
}

variable "cluster_name" {
  description = "A default cluster name"
  default     = "malta"
}

variable "region" {
  description = "The region to host the cluster in"
}

variable "network_name" {
  type    = string
  default = "main"
}

variable "network_cidr" {
  description = "Local subnet rfc1918"
  type        = list(string)
  default     = ["172.16.0.0/16", "fd20:172:1600::/48"]

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
  description = "Admin subnets"
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
