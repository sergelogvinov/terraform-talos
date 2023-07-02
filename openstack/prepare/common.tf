
data "openstack_networking_quota_v2" "quota" {
  for_each   = { for idx, name in var.regions : name => idx }
  region     = each.key
  project_id = var.project_id
}

resource "openstack_compute_keypair_v2" "keypair" {
  for_each   = { for idx, name in var.regions : name => idx }
  region     = each.key
  name       = "Terraform"
  public_key = file("~/.ssh/terraform.pub")
}

data "openstack_images_image_v2" "debian" {
  for_each    = { for idx, name in var.regions : name => idx }
  region      = each.key
  name        = "Debian 11"
  most_recent = true
  visibility  = "public"
}
