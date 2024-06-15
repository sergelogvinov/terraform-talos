
output "ccm" {
  sensitive = true
  value     = proxmox_virtual_environment_user_token.ccm.value
}

output "csi" {
  sensitive = true
  value     = proxmox_virtual_environment_user_token.csi.value
}
