
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "region" {
  description = "the OCI region where resources will be created"
  type        = string
  default     = null
}

variable "project" {
  type    = string
  default = "main"
}
