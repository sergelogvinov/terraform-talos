
variable "compartment_ocid" {}
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "key_file" {
  default = "~/.oci/oci_main_terraform.pem"
}

variable "project" {
  type    = string
  default = "main"
}

variable "region" {
  description = "the OCI region where resources will be created"
  type        = string
  default     = null
}

variable "tags" {
  description = "Defined Tags of resources"
  type        = map(string)
  default = {
    "Kubernetes.Environment" = "Develop"
  }
}

variable "kubernetes" {
  type = map(string)
  default = {
    podSubnets     = "10.32.0.0/12,fd40:10:32::/102"
    serviceSubnets = "10.200.0.0/22,fd40:10:200::/112"
    nodeSubnets    = "192.168.0.0/16"
    domain         = "cluster.local"
    apiDomain      = "api.cluster.local"
    clusterName    = "talos-k8s-oracle"
    clusterID      = ""
    clusterSecret  = ""
    tokenMachine   = ""
    caMachine      = ""
    token          = ""
    ca             = ""
  }
  sensitive = true
}

variable "vpc_main_cidr" {
  description = "Local subnet rfc1918"
  type        = string
  default     = "172.16.0.0/16"
}

variable "whitelist_admins" {
  description = "Whitelist for administrators"
  default     = ["0.0.0.0/0", "::/0"]
}

variable "whitelist_web" {
  description = "Whitelist for web (default Cloudflare network)"
  default = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "172.64.0.0/13",
    "131.0.72.0/22",
    "104.16.0.0/13",
    "104.24.0.0/14",
  ]
}
