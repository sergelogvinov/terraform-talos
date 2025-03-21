
provider "proxmox" {
  endpoint = "https://${var.proxmox_host}:8006/"
  insecure = true

  api_token = data.sops_file.envs.data["PROXMOX_VE_API_TOKEN"]
  # username = "root@pam"
  # password = data.sops_file.envs.data["PROXMOX_VE_PASSWORD"]

  ssh {
    username = "root"
    agent    = true

    dynamic "node" {
      for_each = var.nodes
      content {
        name    = node.key
        address = node.value.ip4
      }
    }
  }
}

data "sops_file" "envs" {
  source_file = ".env.yaml"
}
