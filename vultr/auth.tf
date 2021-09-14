
provider "vultr" {
  api_key     = var.vultr_api_key
  rate_limit  = 700
  retry_limit = 3
}
