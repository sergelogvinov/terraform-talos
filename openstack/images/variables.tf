
variable "clouds" {
  type        = string
  description = "The config section in clouds.yaml"
  default     = "openstack"
}

variable "regions" {
  type        = list(string)
  description = "The id of the openstack region"
  default     = ["GRA9"]
}
