
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.15.0"
    }
  }
  required_version = ">= 1.5"
}

# terraform {
#   backend "s3" {
#     bucket                      = "YYY"
#     key                         = "images/terraform.tfstate"
#     region                      = local.region
#     endpoint                    = "https://XXX.compat.objectstorage.${local.region}.oraclecloud.com"
#     shared_credentials_file     = "../terraform.tfstate.credentials"
#     skip_region_validation      = true
#     skip_credentials_validation = true
#     skip_metadata_api_check     = true
#     force_path_style            = true
#   }
# }
