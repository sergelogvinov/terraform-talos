
resource "vultr_instance" "controlplane" {
  plan        = "vc2-1c-1gb"
  region      = "ams"
  snapshot_id = "0d6f3e7b-62e6-429b-ac53-53108843ee21"
  label       = "talos"
  tag         = "controlplane"
  hostname    = "master-1"

  enable_ipv6         = true
  private_network_ids = ["329f9a26-d475-41f0-8e1f-b8cf11814848"]
  user_data           = file("talos.yaml")

  backups          = "disabled"
  ddos_protection  = false
  activation_email = false
}
