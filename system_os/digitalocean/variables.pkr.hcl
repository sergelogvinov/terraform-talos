
variable "do_api_token" {
  type      = string
  default   = "${env("DO_API_TOKEN")}"
  sensitive = true
}

variable "do_region" {
  type      = string
  default   = "ams3"
}

variable "talos_version" {
  type    = string
  default = "v1.3.3"
}
