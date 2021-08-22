
resource "scaleway_vpc_private_network" "main" {
  name = "main"
  tags = concat(var.tags, ["infra"])
}
