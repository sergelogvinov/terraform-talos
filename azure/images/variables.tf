
variable "subscription_id" {
  description = "The subscription id"
  type        = string
}

variable "project" {
  description = "The project name"
  type        = string
}

variable "regions" {
  description = "The region name list"
  type        = list(string)
  default     = ["uksouth", "ukwest"]
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
