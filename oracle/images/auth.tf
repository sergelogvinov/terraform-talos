
# openssl genrsa -out ~/.oci/oci_main_terraform.pem 2048
# chmod go-rwx ~/.oci/oci_main_terraform.pem
# openssl rsa -pubout -in ~/.oci/oci_main_terraform.pem -out ~/.oci/oci_main_terraform_public.pem

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.key_file
  region           = var.region
}
