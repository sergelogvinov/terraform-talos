
variable "hcloud_token" {
  description = "The hezner cloud token (export TF_VAR_hcloud_token=$TOKEN)"
  type        = string
  sensitive   = true
}

variable "regions" {
  description = "The id of the hezner region (oreder is important)"
  type        = list(string)
  default     = ["nbg1"]
}

variable "tags" {
  description = "Tags of resources"
  type        = map(string)
  default = {
    environment = "Develop"
  }
}

variable "talos_version" {
  description = "Talos image version"
  type        = string
  default     = "v0.10.0"
}
