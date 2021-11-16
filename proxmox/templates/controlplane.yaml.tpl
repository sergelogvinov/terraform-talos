version: v1alpha1
debug: false
persist: true
machine:
  type: ${type}
  certSANs:
    - "${ipv4_local}"
    - "${ipv4_vip}"
  kubelet:
    extraArgs:
      rotate-server-certificates: true
    nodeIP:
      validSubnets: ${format("%#v",split(",",nodeSubnets))}
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth0
        dhcp: true
        vip:
          ip: ${ipv4_vip}
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
          - fd00::169:254:2:53/128
  install:
    wipe: false
  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096
  systemDiskEncryption:
    state:
      provider: luks2
      options:
        - no_read_workqueue
        - no_write_workqueue
      keys:
        - nodeID: {}
          slot: 0
    ephemeral:
      provider: luks2
      options:
        - no_read_workqueue
        - no_write_workqueue
      keys:
        - nodeID: {}
          slot: 0
cluster:
  controlPlane:
    endpoint: https://${ipv4_vip}:6443
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
  # proxy:
  #   disabled: true
  apiServer:
    certSANs:
      - "${ipv4_local}"
      - "${ipv4_vip}"
  controllerManager:
    extraArgs:
        node-cidr-mask-size-ipv4: 24
        node-cidr-mask-size-ipv6: 112
  scheduler: {}
  etcd: {}
