
resource "random_password" "kubernetes" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "proxmox_virtual_environment_user" "kubernetes" {
  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.ccm.role_id
  }
  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.csi.role_id
  }

  comment  = "Kubernetes"
  password = random_password.kubernetes.result
  user_id  = "kubernetes@pve"
}
