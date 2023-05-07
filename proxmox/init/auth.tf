
provider "proxmox" {
  endpoint = "https://${var.proxmox_host}:8006/"
  insecure = true

  username = var.proxmox_token_id
  password = var.proxmox_token_secret
}
