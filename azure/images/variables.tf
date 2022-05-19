
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

variable "tags" {
  description = "Tags to set on resources"
  type        = map(string)
  default = {
    environment = "Develop"
  }
}
