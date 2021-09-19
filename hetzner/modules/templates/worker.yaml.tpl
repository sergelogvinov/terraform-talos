version: v1alpha1
debug: false
persist: true
machine:
  type: worker
  token: ${tokenmachine}
  certSANs: []
  kubelet:
    extraArgs:
      node-ip: "${ipv4}"
      cloud-provider: external
      rotate-server-certificates: true
      node-labels: "${labels}"
  network:
    hostname: "${name}"
    interfaces:
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
          - fd00::169:254:2:53/128
  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096
  install:
    wipe: false
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
cluster:
  controlPlane:
    endpoint: https://${ipv4_vip}:6443
  clusterName: ${cluster_name}
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
  token: ${token}
  ca:
    crt: ${ca}
    key: ""
