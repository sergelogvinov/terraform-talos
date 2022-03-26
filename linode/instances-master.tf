
resource "linode_instance" "controlplane" {
  count = lookup(var.controlplane, "count", 0)
  label = "controlplane-${count.index + 1}"

  region = var.region
  type   = lookup(var.controlplane, "type", "g6-standard-2")
  tags   = concat(var.tags, ["infra", "controlplane"])
  group  = "controlplane"

  private_ip       = true
  watchdog_enabled = true
  booted           = true

  disk {
    label      = "talos"
    size       = data.linode_instance_type.controlplane.disk
    image      = data.linode_images.talos.images[0].id
    filesystem = "raw"
  }

  boot_config_label = "talos"
  config {
    label  = "talos"
    kernel = "linode/direct-disk"
    devices {
      sda {
        disk_label = "talos"
      }
    }
    root_device = "/dev/sda"

    helpers {
      devtmpfs_automount = false
      distro             = false
      modules_dep        = false
      network            = false
      updatedb_disabled  = false
    }
  }
}

resource "local_file" "controlplane" {
  count = lookup(var.controlplane, "count", 0)
  content = templatefile("${path.module}/templates/controlplane.yaml",
    merge(var.kubernetes, {
      name       = "controlplane-${count.index + 1}"
      labels     = "topology.kubernetes.io/region=${var.region}"
      ipv4_vip   = "127.0.0.1"
      ipv4_local = linode_instance.controlplane[count.index].private_ip_address
    })
  )

  filename        = "_cfgs/controlplane-${count.index + 1}.yaml"
  file_permission = "0600"
}

resource "null_resource" "controlplane" {
  count = lookup(var.controlplane, "count", 0)
  provisioner "local-exec" {
    command = "sleep 60 && talosctl apply-config --insecure --nodes ${linode_instance.controlplane[count.index].ip_address} --file _cfgs/controlplane-${count.index + 1}.yaml"
  }
  depends_on = [local_file.controlplane]
}
