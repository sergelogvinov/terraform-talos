# Proxmox

## Agenda

* create VM config in directory `/etc/pve/qemu-server/VMID.conf`
* allow cloud-init on VM
* prepare network config
* upload user-data (talos machine config) to the Proxmox host
* upload meta-data to the Proxmox host

Result VM config:

```yaml
# /etc/pve/qemu-server/VMID.conf
cpu: host
cicustom: user=local:snippets/VMID.yaml,meta=local:snippets/VMID.meta
ipconfig0: ...
net0: ...
```
