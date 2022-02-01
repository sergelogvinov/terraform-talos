
# openssl genrsa -out ~/.oci/oci_api_key.pem 2048
# chmod go-rwx ~/.oci/oci_api_key.pem
# openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.key_file
  region           = var.region
}
