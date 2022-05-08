
# data "openstack_identity_auth_scope_v3" "os" {
#   name = var.openstack_project
# }

data "openstack_images_image_v2" "talos" {
  for_each = { for idx, name in local.regions : name => idx }
  region   = each.key

  name = "talos"
  # name        = "Debian 11"
  most_recent = true
}

data "openstack_compute_keypair_v2" "terraform" {
  for_each = { for idx, name in local.regions : name => idx }
  region   = each.key

  name = "Terraform"
}
