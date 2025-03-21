
provider "proxmox" {
  endpoint = "https://${var.proxmox_host}:8006/"
  insecure = true

  api_token = "${var.proxmox_token_id}=${var.proxmox_token_secret}"
}
