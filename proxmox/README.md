# Proxmox

It was tested on Proxmox version 7.4-3

## Agenda

* create VM config in directory `/etc/pve/qemu-server/VMID.conf`
* allow cloud-init on VM
* prepare network config
* upload user-data (talos machine config) to the Proxmox host
* upload meta-data to the Proxmox host

## VM template

First we need to upload the talos OS image to the Proxmox host machine.
If you do not have shared storage, you need to upload image to each machine.

Folow this link [README](images/README.md) to make it.

## Init

Create Proxmox role and account.
This credentials will use by Proxmox CCM and CSI.

```shell
cd init
terraform init -upgrade
terraform apply
```

## Bootstrap cluster

Result VM config:

```yaml
# /etc/pve/qemu-server/VMID.conf
cpu: host
cicustom: user=local:snippets/VMID.yaml,meta=local:snippets/VMID.meta
ipconfig0: ...
net0: ...
```

```shell
make create-config create-templates
```
