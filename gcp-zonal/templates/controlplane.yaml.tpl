version: v1alpha1
debug: false
persist: true
machine:
  type: ${type}
  certSANs:
    - "${lbv4}"
    - "${lbv4_local}"
    - "${ipv4}"
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
        cidr: ${lbv4_local}/32
      - interface: eth0
        cidr: ${lbv4}/32
      - interface: dummy0
        cidr: "169.254.2.53/32"
      - interface: dummy0
        cidr: "fd00::169:254:2:53/128"
  install:
    disk: /dev/sda
    bootloader: true
    wipe: false
    extraKernelArgs:
      - elevator=noop
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
    cni:
      name: custom
      urls:
        - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/gcp-zonal/deployments/cilium_result.yaml
  proxy:
    disabled: true
    mode: ipvs
  apiServer:
    certSANs:
      - "${lbv4_local}"
      - "${lbv4}"
      - "${ipv4}"
  controllerManager: {}
  scheduler: {}
  etcd: {}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/gcp-zonal/deployments/kubelet-serving-cert-approver.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/gcp-zonal/deployments/metrics-server.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/gcp-zonal/deployments/local-path-storage.yaml
