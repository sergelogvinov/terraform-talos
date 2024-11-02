
variable "cpu_affinity" {
  description = "CPU numa affinity list"
  type        = list(string)
  default     = ["0-15,64-79", "16-31,80-95", "32-47,96-111", "48-63,112-127"]
}

variable "vms" {
  type    = number
  default = 2
}

variable "cpus" {
  type    = number
  default = 16
}

variable "shift" {
  type    = number
  default = 0
}

locals {
  server_cpus = [for i in var.cpu_affinity :
    flatten([for r in split(",", i) : (strcontains(r, "-") ? range(split("-", r)[0], split("-", r)[1] + 1, 1) : [r])])
  ]

  cpus = [for k, v in local.server_cpus :
    flatten([flatten([for r in range(length(v) / 2) : [v[r], v[r + length(v) / 2]]])])
  ]

  shift = var.shift * length(try(local.cpus[0], []))

  vm_arch = { for k in flatten([
    for inx in range(var.vms) : {
      inx : inx
      cpus : slice(flatten(local.cpus), inx * var.cpus + local.shift, (inx + 1) * var.cpus + local.shift)
      numa : { for numa in range(length(var.cpu_affinity)) : numa => setintersection(local.cpus[numa], slice(flatten(local.cpus), inx * var.cpus + local.shift, (inx + 1) * var.cpus + local.shift)) }
    }
  ]) : k.inx => k }
}
