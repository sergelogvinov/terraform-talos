# Upload Talos image

We will use `nocloud` image.

## Method 1: packer

```
make init
make release
```

## Method 1: manual

Create the VM, config example:

```yaml
agent: 0
boot: order=scsi0;ide2;net0
cores: 1
cpu: host
kvm: 1
balloon: 0
memory: 3072
name: talos
net0: virtio=...
onboot: 0
ostype: l26
ide2: cdrom,media=cdrom
scsi0: local-lvm:vm-106-disk-0,size=32G
scsihw: virtio-scsi-single
serial0: socket
smbios1: uuid=...
numa: 0
sockets: 1
template: 1
```

Find the name of system disk.
In example it - `local-lvm:vm-106-disk-0`, lvm volume `vm-106-disk-0`

We copy Talos system disk to this volume.

```shell
cd /tmp
wget https://github.com/siderolabs/talos/releases/download/v1.4.1/nocloud-amd64.raw.xz
xz -d -c nocloud-amd64.raw.xz | dd of=/dev/mapper/vg0-vm--106--disk--0
```

And then, convert it to template.

# Resources

* https://developer.hashicorp.com/packer/plugins/builders/proxmox/iso
* https://wiki.archlinux.org/title/Arch_Linux_on_a_VPS
