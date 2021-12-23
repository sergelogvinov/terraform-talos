
variable "compartment_ocid" {}
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "key_file" {
  default = "~/.oci/oci_public.pem"
}

variable "region" {
  description = "the OCI region where resources will be created"
  type        = string
  default     = null
}
