machine:
  kubelet:
    extraArgs:
      cloud-provider: external
      rotate-server-certificates: true
      node-labels: "project.io/node-pool=worker"
    clusterDNS:
      - 169.254.2.53
      - 10.200.0.10
    nodeIP:
      validSubnets: ["172.16.0.0/24"]
  network:
    interfaces:
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
    extraHostEntries:
      - ip: 172.16.0.10
        aliases:
          - api.cluster.local
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
    endpoint: https://api.cluster.local:6443
  proxy:
    disabled: true
