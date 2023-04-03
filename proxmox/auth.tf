
# provider "proxmox" {
#   virtual_environment {
#     endpoint = "https://${var.proxmox_host}:8006/"
#     insecure = true

#     username = var.proxmox_token_id
#     password = var.proxmox_token_secret
#   }
# }

provider "proxmox" {
  pm_api_url          = "https://${var.proxmox_host}:8006/api2/json"
  pm_api_token_id     = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure     = true
  pm_debug            = true
}
