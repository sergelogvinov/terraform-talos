version: v1alpha1
debug: false
persist: true
machine:
  type: ${type}
  certSANs:
    - "${lbv4}"
    - "${ipv4}"
  kubelet:
    extraArgs:
      rotate-server-certificates: true
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth1
        dhcp: true
        dhcpOptions:
          routeMetric: 2048
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
    ephemeral:
      provider: luks2
      keys:
        - nodeID: {}
          slot: 0
cluster:
  controlPlane:
    endpoint: https://${lbv4}:6443
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("[%s]",podSubnets)}
    serviceSubnets: ${format("[%s]",serviceSubnets)}
  proxy:
    mode: ipvs
  apiServer:
    certSANs:
      - "${lbv4}"
      - "${ipv4}"
  controllerManager:
    extraArgs:
        node-cidr-mask-size-ipv4: 24
        node-cidr-mask-size-ipv6: 112
  scheduler: {}
  etcd: {}
  extraManifests:
    - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/kubelet-serving-cert-approver.yaml
    - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/metrics-server.yaml
    - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/local-path-storage.yaml
