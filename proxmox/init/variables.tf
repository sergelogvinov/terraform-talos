
variable "proxmox_host" {
  description = "Proxmox host"
  type        = string
  default     = "192.168.1.1"
}

variable "proxmox_token_id" {
  description = "Proxmox token id"
  type        = string
  default     = ""
}

variable "proxmox_token_secret" {
  description = "Proxmox token secret"
  type        = string
  default     = ""
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  default     = ""
}
