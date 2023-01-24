
variable "project" {
  description = "The project ID to host the cluster in"
}

variable "region" {
  description = "The region to host the cluster in"
}

variable "talos_version" {
  default = "v1.3.3"
}
