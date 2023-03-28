# Proxmox hypervisor

Apply a few changes to the proxmox node.
* ipv4 NAT
* cpu governor to `schedutil` (by default it is `performance`)
* ipv4/v6 forwarding

1. Download the galaxy roles:

```shell
ansible-galaxy role install git+https://github.com/sergelogvinov/ansible-role-system.git,main
ansible-galaxy role install git+https://github.com/sergelogvinov/ansible-role-users.git,main
ansible-galaxy role install git+https://github.com/sergelogvinov/ansible-role-iptables.git,main
```

2. Update inventory file, replace the host ip here `ansible_host`

```ini
# proxmox.ini
[pve]
proxmox-1       ansible_host=1.2.3.1 ansible_ssh_user=root
proxmox-2       ansible_host=1.2.3.2 ansible_ssh_user=root
```

3. Apply optimizations:

```shell
make prepare
```

## Proxmox network

Proxmox is based on linux (debian), we can use firewall/NAT-v4 on the host.
And IPv6 to direct connect to the VM.

Do not forget to switch on IPv6 firewall for the VM.

### One interface on VM

The server has IPv6/64 subnet.
We can use global IPv6 on each VM, and local IPv4 with NAT-v4

Host network config:

* IPv4, IPv6/64 - public internet
* 192.168.0.0/24 - local neetwork

```config
# /etc/network/interfaces

auto eth0
iface eth0 inet static
    address IPv4
    gateway IPv4-GW

iface eth0 inet6 static
    address IPv6:1/64
    gateway IPv6-GW

auto eth1
iface eth1 inet manual

auto vmbr0
iface vmbr0 inet static
    address 192.168.0.1/24
    bridge-ports eth1
    bridge-stp off
    bridge-fd 0

iface vmbr0 inet6 static
    address IPv6:8100::2/64
    up ip -6 route add IPv6:8100::/68 dev vmbr0
```

IPv6 tricks:

* Host has IPv6 `a:b:c:d::/64`
* MAC Address prefix - 81 (/etc/pve/datacenter.cfg)
* IPv6 for VM looks like `a:b:c:d:8100:../68` - `a:b:c:d:81ff:../68`

VM network config:

```config
# /etc/pve/qemu-server/ID.conf
net0: virtio=81:0B:E8:85:D2:F1,bridge=vmbr0,firewall=1
ipconfig0: ip=192.168.0.11/24,gw=192.168.0.1,ip6=a:b:c:d:8100b:e8ff:fe85:d2f1/64,gw6=a:b:c:d:8100::2
```

IPv6 looks like SLAAC does, but it is static here.

### Two interfaces on VM

First interface - public internet,
second - local network.

Host network config:

* IPv4, IPv6/64 - public internet
* 192.168.0.0/24 - local neetwork

```config
# /etc/network/interfaces

iface eth0 inet manual
iface eth1 inet manual

auto vmbr0
iface vmbr0 inet static
    address IPv4
    gateway IPv4-GW
    bridge-ports eth0
    bridge-stp off
    bridge-fd 0

iface vmbr0 inet6 static
    address IPv6:1/64
    gateway IPv6-GW

auto vmbr1
iface vmbr1 inet static
    address 192.168.0.1/24
    bridge-ports eth1
    bridge-stp off
    bridge-fd 0
```

VM network config:

```config
# /etc/pve/qemu-server/ID.conf
net0: virtio=81:0B:E8:85:D2:F1,bridge=vmbr0,firewall=1
net1: virtio=81:0B:E8:85:D2:F2,bridge=vmbr1
ipconfig0: ip6=a:b:c:d::41/64,gw6=a:b:c:d::1
ipconfig1: ip=192.168.0.41/24,gw=172.16.0.1
```
