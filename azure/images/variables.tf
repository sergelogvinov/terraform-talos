
variable "subscription_id" {
  description = "The subscription id"
  type        = string
}

variable "resource_group" {
  description = "The existed resource group"
  type        = string
}

variable "regions" {
  description = "The region name list"
  type        = list(string)
  default     = ["uksouth", "ukwest"]
}

variable "name" {
  description = "The image name"
  type        = string
  default     = "talos"
}

variable "release" {
  description = "The image name"
  type        = string
  default     = "1.3.4"
}

variable "arch" {
  description = "The Talos architecture list"
  type        = list(string)
  default     = ["x64", "Arm64"]
}

variable "tags" {
  description = "Tags to set on resources"
  type        = map(string)
  default = {
    environment = "Develop"
  }
}
