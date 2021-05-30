
variable "location" {
  type    = string
  default = "nbg1"
}

variable "labels" {
  type        = map(string)
  description = "Tags of resources"
}

variable "network" {
  type        = string
  description = "Network id"
}

variable "subnet" {
  type        = string
  description = "Subnet cidr"
}

variable "vm_name" {
  type    = string
  default = "worker-"
}

variable "vm_items" {
  type    = number
  default = 0
}

variable "vm_type" {
  type    = string
  default = "cx11"
}

variable "vm_image" {
  type = string
}

variable "vm_security_group" {
  type = list(string)
}

variable "vm_ip_start" {
  type    = number
  default = 61
}

variable "vm_params" {
  type = map(string)
}
