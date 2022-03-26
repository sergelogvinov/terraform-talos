
data "linode_images" "talos" {
  filter {
    name   = "label"
    values = ["talos"]
  }

  filter {
    name   = "is_public"
    values = ["false"]
  }
}

data "linode_instance_type" "controlplane" {
  id = lookup(var.controlplane, "type", "g6-standard-2")
}
