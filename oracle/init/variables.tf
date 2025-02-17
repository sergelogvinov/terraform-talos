
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_api_key_file" {}
variable "private_tf_key_file" {
  description = "Filepath to write new private key"
  default     = "~/.oci/oci_main_terraform.pem"
}
variable "public_tf_key_file" {
  description = "Filepath to write new public key"
  default     = "~/.oci/oci_main_terraform_public.pem"
}
variable "region" {
  description = "the OCI region where resources will be created"
  type        = string
  default     = null
}

variable "project" {
  type    = string
  default = "main"
}

variable "tags" {
  description = "Defined Tags of resources"
  type        = map(string)
  default = {
    "Environment" = "Resource environment"
    "Role"        = "Kubernetes node role"
    "Type"        = "Type of resource"
  }
}
