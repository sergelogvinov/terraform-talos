
data "vultr_snapshot" "talos" {
  filter {
    name   = "description"
    values = ["talos system disk"]
  }
}

resource "vultr_vpc" "main" {
  description    = "main"
  region         = "ams"
  v4_subnet      = "10.0.0.0"
  v4_subnet_mask = 24
}

resource "vultr_instance" "controlplane" {
  plan        = "vc2-2c-4gb"
  region      = "ams"
  snapshot_id = data.vultr_snapshot.talos.id
  label       = "talos"
  hostname    = "controlplane-1"

  enable_ipv6 = true
  vpc_ids     = [vultr_vpc.main.id]
  user_data   = file("talos.yaml")

  backups          = "disabled"
  ddos_protection  = false
  activation_email = false

  tags = ["develop", "test"]
}
