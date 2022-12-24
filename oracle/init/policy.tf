
resource "oci_identity_policy" "terraform" {
  name           = "terraform"
  description    = "policy created by terraform for terraform"
  compartment_id = oci_identity_compartment.project.id

  statements = [
    "Allow group ${oci_identity_group.terraform.name} to use tag-namespaces in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to manage virtual-network-family in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to manage load-balancers in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to manage dns in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to manage compute-management-family in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to manage instances in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to manage instance-family in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to manage compute-image-capability-schema in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to read objectstorage-namespaces in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to manage buckets in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to manage objects in compartment ${oci_identity_compartment.project.name}",

    "Allow group ${oci_identity_group.terraform.name} to manage volumes in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.terraform.name} to manage volume-attachments in compartment ${oci_identity_compartment.project.name}",
  ]
}

resource "oci_identity_policy" "ccm" {
  name           = "ccm"
  description    = "This is a kubernetes role for CCM, created via Terraform"
  compartment_id = oci_identity_compartment.project.id

  # https://github.com/oracle/oci-cloud-controller-manager/blob/master/manifests/provider-config-example.yaml
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm.name} to read instance-family in compartment ${oci_identity_compartment.project.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm.name} to read virtual-network-family in compartment ${oci_identity_compartment.project.name}",
    # "Allow dynamic-group ${oci_identity_dynamic_group.ccm.name} to manage load-balancers in compartment ${oci_identity_compartment.project.name}",
  ]
}

resource "oci_identity_policy" "csi" {
  name           = "csi"
  description    = "This is a kubernetes role for CSI, created via Terraform"
  compartment_id = oci_identity_compartment.project.id

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm.name} to manage volumes in compartment ${oci_identity_compartment.project.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm.name} to manage volume-attachments in compartment ${oci_identity_compartment.project.name}",
  ]
}

resource "oci_identity_policy" "scaler" {
  name           = "scaler"
  description    = "This is a kubernetes role for node autoscaler system, created via Terraform"
  compartment_id = oci_identity_compartment.project.id

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm.name} to manage instance-pools in compartment ${oci_identity_compartment.project.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm.name} to manage instance-configurations in compartment ${oci_identity_compartment.project.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm.name} to manage instance-family in compartment ${oci_identity_compartment.project.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm.name} to use subnets in compartment ${oci_identity_compartment.project.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm.name} to read virtual-network-family in compartment ${oci_identity_compartment.project.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm.name} to use vnics in compartment ${oci_identity_compartment.project.name}",
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
