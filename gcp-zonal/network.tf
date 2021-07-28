
module "gcp-network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 3.3"

  project_id   = var.project_id
  network_name = var.network
  routing_mode = "REGIONAL"
  mtu          = 1500

  subnets = [
    {
      subnet_name           = "core"
      subnet_ip             = cidrsubnet(var.network_cidr, 8, 0)
      subnet_region         = var.region
      subnet_private_access = "true"
    },
    {
      subnet_name           = "private"
      subnet_ip             = cidrsubnet(var.network_cidr, 8, 1)
      subnet_region         = var.region
      subnet_private_access = "true"
    },
  ]
}
