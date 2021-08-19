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
      - interface: eth1
        dhcp: true
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
    podSubnets: ${format("[%s]",podSubnets)}
    serviceSubnets: ${format("[%s]",serviceSubnets)}
  proxy:
    mode: ipvs
  token: ${token}
  ca:
    crt: ${ca}
    key: ""
