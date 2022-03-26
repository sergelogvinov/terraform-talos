version: v1alpha1
debug: false
persist: true
machine:
  type: controlplane
  certSANs:
    - "${ipv4_vip}"
    - "${ipv4_local}"
    - "${apiDomain}"
  kubelet:
    extraArgs:
      node-ip: "${ipv4_local}"
      node-labels: "${labels}"
      # rotate-server-certificates: true
    clusterDNS:
      - 169.254.2.53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth0
        dhcp: true
        addresses:
          - ${ipv4_local}/17
  install:
    wipe: false
  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096
cluster:
  controlPlane:
    endpoint: https://${ipv4_vip}:6443
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
  apiServer:
    certSANs:
    - "${ipv4_vip}"
    - "${ipv4_local}"
    - "${apiDomain}"
  controllerManager:
    extraArgs:
        node-cidr-mask-size-ipv4: 24
        node-cidr-mask-size-ipv6: 112
  scheduler: {}
  etcd: {}
