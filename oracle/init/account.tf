
resource "oci_identity_compartment" "project" {
  name           = var.project
  description    = "Compartment created for ${var.project} project"
  compartment_id = var.tenancy_ocid
  enable_delete  = false
}

resource "oci_identity_group" "operator" {
  name           = "operator"
  description    = "group created by terraform for operators"
  compartment_id = var.tenancy_ocid
}

resource "oci_identity_group" "terraform" {
  name           = "terraform"
  description    = "group created by terraform for terraform"
  compartment_id = var.tenancy_ocid
}

resource "oci_identity_user" "terraform" {
  name           = "terraform"
  description    = "user created by terraform for terraform"
  compartment_id = var.tenancy_ocid
}

resource "oci_identity_user_group_membership" "terraform" {
  compartment_id = var.tenancy_ocid
  user_id        = oci_identity_user.terraform.id
  group_id       = oci_identity_group.terraform.id
}

resource "oci_identity_user_capabilities_management" "terraform" {
  user_id                      = oci_identity_user.terraform.id
  can_use_api_keys             = true
  can_use_auth_tokens          = false
  can_use_console_password     = false
  can_use_customer_secret_keys = false
  can_use_smtp_credentials     = false
}

resource "null_resource" "terraform_key" {
  provisioner "local-exec" {
    command = "openssl genrsa -out ~/.oci/oci_${var.project}_terraform.pem 2048 && openssl rsa -pubout -in ~/.oci/oci_${var.project}_terraform.pem -out ~/.oci/oci_${var.project}_terraform_public.pem"
  }
}

resource "oci_identity_api_key" "terraform" {
  user_id   = oci_identity_user.terraform.id
  key_value = file(pathexpand("~/.oci/oci_${var.project}_terraform_public.pem"))

  depends_on = [null_resource.terraform_key]
}

resource "oci_identity_dynamic_group" "ccm" {
  compartment_id = var.tenancy_ocid
  name           = "oci-ccm"
  description    = "dynamic group created by terraform for oci-cloud-controller-manager"
  matching_rule  = "ALL {instance.compartment.id = '${oci_identity_compartment.project.id}', tag.Kubernetes.Role.value = 'contolplane'}"
}
