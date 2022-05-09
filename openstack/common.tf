
data "openstack_identity_auth_scope_v3" "scope" {
  name = "scope"
}

locals {
  project_domain_name = data.openstack_identity_auth_scope_v3.scope.project_domain_name
  project_id          = data.openstack_identity_auth_scope_v3.scope.project_id

  openstack_auth_identity = [for entry in data.openstack_identity_auth_scope_v3.scope.service_catalog :
  entry if entry.type == "identity"][0]

  openstack_auth = [for endpoint in local.openstack_auth_identity.endpoints :
  endpoint if(endpoint.interface == "internal" && endpoint.region == "${local.regions[0]}")][0]

  openstack_auth_url = local.openstack_auth.url
}

data "openstack_images_image_v2" "talos" {
  for_each = { for idx, name in local.regions : name => idx }
  region   = each.key

  name        = "talos"
  most_recent = true
}
