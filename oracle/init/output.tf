
output "compartment_ocid" {
  description = "compartment id"
  value       = oci_identity_compartment.project.id
}

output "user_ocid" {
  description = "user id"
  value       = oci_identity_user.terraform.id
}

output "key_file" {
  description = "key_file"
  value       = "~/.oci/oci_${var.project}_terraform.pem"
}

output "tags" {
  description = "tags"
  value       = [for tag, value in var.tags : "${oci_identity_tag_namespace.kubernetes.name}.${tag}"]
}
