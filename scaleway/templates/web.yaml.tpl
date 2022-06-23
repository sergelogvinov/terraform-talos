version: v1alpha1
debug: false
persist: true
machine:
  type: worker
  token: ${tokenMachine}
  ca:
    crt: ${caMachine}
  certSANs: []
  kubelet:
    extraArgs:
      cloud-provider: external
      rotate-server-certificates: true
      node-labels: ${labels}
    clusterDNS:
      - 169.254.2.53
      - ${clusterDns}
    nodeIP:
      validSubnets: ${format("%#v",split(",",nodeSubnets))}
  network:
    interfaces:
      - interface: eth0
        dhcp: true
        dhcpOptions:
          routeMetric: 2048
        routes:
          - network: 169.254.42.42/32
            metric: 1024
      - interface: eth1
        dhcp: true
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
    kubespan:
      enabled: false
      allowDownPeerBypass: true
    extraHostEntries:
      - ip: ${ipv4_vip}
        aliases:
          - ${apiDomain}
  install:
    wipe: true
  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096
  systemDiskEncryption:
    state:
      provider: luks2
      keys:
        - nodeID: {}
          slot: 0
cluster:
  id: ${clusterID}
  secret: ${clusterSecret}
  controlPlane:
    endpoint: https://${ipv4_vip}:6443
  clusterName: ${clusterName}
  discovery:
    enabled: false
    registries:
      service:
        disabled: true
  network:
    dnsDomain: ${domain}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
  proxy:
    disabled: true
  token: ${token}
  ca:
    crt: ${ca}
