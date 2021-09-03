
resource "hcloud_ssh_key" "snapshot" {
  name       = "Snapshoter"
  public_key = file("~/.ssh/terraform.pub")
  labels     = merge(var.tags, { type = "infra" })
}

resource "hcloud_server" "talos" {
  location     = element(var.regions, 1)
  name         = "talos-os"
  image        = "debian-10"
  rescue       = "linux64"
  server_type  = "cx11"
  keep_disk    = true
  backups      = false
  ssh_keys     = [hcloud_ssh_key.snapshot.id]
  firewall_ids = []
  labels       = merge(var.tags, { type = "infra", label = "template" })

  lifecycle {
    ignore_changes = [
      firewall_ids,
      status,
      ssh_keys,
    ]
  }

  connection {
    user        = "root"
    private_key = file("~/.ssh/terraform")
    host        = self.ipv4_address
    timeout     = "10m"
  }
  provisioner "remote-exec" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/openstack.tar.gz https://github.com/talos-systems/talos/releases/download/${var.talos_version}/openstack-amd64.tar.gz",
      "cd /tmp && tar xzf /tmp/openstack.tar.gz && dd if=/tmp/disk.raw of=/dev/sda && sync",
      "mount /dev/sda3 /mnt && sed -i 's/set timeout=3/set timeout=10/g' /mnt/grub/grub.cfg && umount /mnt",
      "shutdown -h now"
    ]
  }
}

resource "hcloud_snapshot" "talos" {
  server_id   = hcloud_server.talos.id
  description = "talos system disk"
  labels      = merge(var.tags, { type = "infra" })
  depends_on  = [hcloud_server.talos]
}
