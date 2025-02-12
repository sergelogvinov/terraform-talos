
output "compartment_ocid" {
  description = "compartment id"
  value       = oci_identity_compartment.project.id
}

output "user_ocid" {
  description = "user id"
  value       = oci_identity_user.terraform.id
}

output "private_tf_key_file" {
  description = "private_tf_key_file"
  value       = var.private_tf_key_file
}

output "private_api_key_file" {
  description = "public_tf_key_file"
  value       = var.public_tf_key_file
}

output "tags" {
  description = "tags"
  value       = [for tag, value in var.tags : "${oci_identity_tag_namespace.kubernetes.name}.${tag}"]
}
