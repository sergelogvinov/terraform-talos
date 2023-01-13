
variable "access_key" {}
variable "secret_key" {}

variable "name" {
  description = "Project name, required to create unique resource names"
  type        = string
}

variable "region" {
  description = "The region name"
  type        = string
  default     = "us-east-2"
}

variable "network_cidr" {
  description = "Local subnet rfc1918/ULA"
  type        = string
  default     = "172.16.0.0/16"
}

variable "network_shift" {
  description = "Network number shift"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags of resources"
  type        = map(string)
  default = {
    Name        = "talos"
    Environment = "Develop"
  }
}
