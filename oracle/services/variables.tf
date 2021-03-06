
variable "compartment_ocid" {}
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}

variable "project" {
  type    = string
  default = "main"
}

variable "region" {
  description = "the OCI region where resources will be created"
  type        = string
  default     = null
}
