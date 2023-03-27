# Proxmox

Apply a few changes to the proxmox node.
* ipv4 NAT
* cpu governor to `schedutil` (by default it is `performance`)
* ipv4/v6 forwarding

Inventory file, set the ip here `ansible_host`

```ini
[pve]
proxmox-1       ansible_host=1.2.3.1 ansible_ssh_user=root
proxmox-2       ansible_host=1.2.3.2 ansible_ssh_user=root
```

Apply optimizations:

```shell
make prepare
```
