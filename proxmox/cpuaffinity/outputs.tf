
output "arch" {
  value = { for k, v in local.vm_arch : k => {
    cpus : v.cpus
    numa : { for numa in range(length(var.cpu_affinity)) : numa => v.numa[numa] if length(v.numa[numa]) > 0 }
    }
  }
}
