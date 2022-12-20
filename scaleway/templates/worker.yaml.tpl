version: v1alpha1
debug: false
persist: true
machine:
  type: worker
  token: ${tokenMachine}
  ca:
    crt: ${caMachine}
  nodeLabels:
    node.kubernetes.io/disktype: ssd
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
    hostname: "${name}"
    interfaces:
      - interface: eth0
        dhcp: true
        dhcpOptions:
          routeMetric: 2048
        routes:
          - network: 169.254.42.42/32
            metric: 1024
      - interface: eth1
        addresses:
          - ${ipv4}/24
        routes:
          - network: 0.0.0.0/0
            gateway: ${ipv4_gw}
            metric: 512
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
    kubespan:
      enabled: true
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
    ephemeral:
      provider: luks2
      keys:
        - nodeID: {}
          slot: 0
      options:
        - no_read_workqueue
        - no_write_workqueue
cluster:
  id: ${clusterID}
  secret: ${clusterSecret}
  controlPlane:
    endpoint: https://${apiDomain}:6443
  clusterName: ${clusterName}
  discovery:
    enabled: true
  network:
    dnsDomain: ${domain}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
  proxy:
    disabled: true
  token: ${token}
  ca:
    crt: ${ca}
