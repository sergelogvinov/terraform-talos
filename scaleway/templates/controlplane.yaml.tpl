version: v1alpha1
debug: false
persist: true
machine:
  type: ${type}
  certSANs:
    - "${lbv4}"
    - "${ipv4}"
    - "${ipv4_local}"
    - "${ipv4_vip}"
  kubelet:
    extraArgs:
      node-ip: "${ipv4_local}"
      rotate-server-certificates: true
      node-labels: "${labels}"
    clusterDNS:
      - 169.254.2.53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
    nodeIP:
      validSubnets: ${format("%#v",split(",",nodeSubnets))}
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth1
        addresses:
          - ${ipv4_local}/24
        vip:
          ip: ${ipv4_vip}
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
          - fd00::169:254:2:53/128
    kubespan:
      enabled: true
  install:
    wipe: false
  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096
  systemDiskEncryption:
    state:
      provider: luks2
      keys:
        - nodeID: {}
          slot: 0
    ephemeral:
      provider: luks2
      keys:
        - nodeID: {}
          slot: 0
      options:
        - no_read_workqueue
        - no_write_workqueue
cluster:
  controlPlane:
    endpoint: https://${ipv4_vip}:6443
  discovery:
    enabled: true
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
    cni:
      name: custom
      urls:
        - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/cilium_result.yaml
  proxy:
    disabled: true
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
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/kubelet-serving-cert-approver.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/metrics-server.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/local-path-storage.yaml
