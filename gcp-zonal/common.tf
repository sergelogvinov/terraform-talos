
data "google_client_openid_userinfo" "terraform" {}

resource "google_os_login_ssh_public_key" "terraform" {
  project = var.project_id
  user    = data.google_client_openid_userinfo.terraform.email
  key     = file("~/.ssh/terraform.pub")
}
