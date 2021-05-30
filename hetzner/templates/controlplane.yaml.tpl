version: v1alpha1
debug: false
persist: true
machine:
  type: ${type}
  certSANs:
    - "${lbv4}"
    - "${lbv6}"
    - "${lbv4_local}"
    - "${ipv4}"
    - "${ipv6}"
  kubelet:
    extraArgs:
      node-ip: "${ipv4_local}"
      rotate-server-certificates: true
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth0
        dhcp: true
      - interface: eth0
        cidr: "${ipv6}/64"
      - interface: eth1
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
    wipe: false
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
    podSubnets:
    - ${podSubnets}
    serviceSubnets:
    - ${serviceSubnets}
  proxy:
    mode: ipvs
  apiServer:
    certSANs:
      - "${lbv4_local}"
      - "${lbv4}"
      - "${lbv6}"
      - "${ipv4}"
  controllerManager: {}
  scheduler: {}
  etcd: {}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/latest/download/ccm.yaml
      - https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/main/deploy/standalone-install.yaml
      - https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
