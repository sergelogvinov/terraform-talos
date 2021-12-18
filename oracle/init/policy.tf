
resource "oci_identity_policy" "terraform" {
  name           = "terraform"
  description    = "policy created by terraform for terraform"
  compartment_id = oci_identity_compartment.project.id

  statements = [
    "Allow group ${oci_identity_group.terraform.name} to manage virtual-network-family in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to manage load-balancers in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to manage compute-management-family in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to manage instance-family in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to manage instance-images in compartment ${oci_identity_compartment.project.name}",
  ]
}

resource "oci_identity_policy" "operator" {
  name           = "operator"
  description    = "policy created by terraform for operators"
  compartment_id = oci_identity_compartment.project.id

  statements = [
    "Allow group ${oci_identity_group.operator.name} to use instance-pools in compartment ${oci_identity_compartment.project.name}",
  ]
}
