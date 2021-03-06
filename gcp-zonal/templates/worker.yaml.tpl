version: v1alpha1
debug: false
persist: true
machine:
  type: worker
  token: ${tokenmachine}
  certSANs: []
  kubelet:
    extraArgs:
      cloud-provider: external
      rotate-server-certificates: true
  network:
    interfaces:
      - interface: eth0
        dhcp: true
      - interface: dummy0
        cidr: "169.254.2.53/32"
      - interface: dummy0
        cidr: "fd00::169:254:2:53/128"
  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096
  install:
    disk: /dev/sda
    extraKernelArgs:
      - elevator=noop
    bootloader: true
    wipe: true
  systemDiskEncryption:
    ephemeral:
      provider: luks2
      keys:
        - nodeID: {}
          slot: 0
cluster:
  controlPlane:
    endpoint: https://${lbv4}:6443
  clusterName: ${cluster_name}
  network:
    dnsDomain: ${domain}
  proxy:
    mode: ipvs
  token: ${token}
  ca:
    crt: ${ca}
    key: ""
