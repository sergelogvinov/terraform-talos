
provider "openstack" {
  auth_url    = var.openstack_api
  user_name   = var.openstack_user
  password    = var.openstack_password
  tenant_id   = var.openstack_tenant_id
  tenant_name = var.openstack_tenant_name
}
