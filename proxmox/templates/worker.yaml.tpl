version: v1alpha1
debug: false
persist: true
machine:
  type: worker
  token: ${tokenMachine}
  ca:
    crt: ${caMachine}
  kubelet:
    image: ghcr.io/siderolabs/kubelet:${version}
    defaultRuntimeSeccompProfileEnabled: true
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
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
    extraHostEntries:
      - ip: ${lbv4}
        aliases:
          - ${apiDomain}
    nameservers:
      - 2606:4700:4700::1111
      - 1.1.1.1
      - 2001:4860:4860::8888
  time:
    servers:
      - 2.europe.pool.ntp.org
      - time.cloudflare.com
  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096
    net.ipv4.tcp_keepalive_intvl: 60
    net.ipv4.tcp_keepalive_time: 600
    vm.max_map_count: 128000
  install:
    wipe: true
    extraKernelArgs:
      - talos.dashboard.disabled=1
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
  features:
    rbac: true
    stableHostname: true
    apidCheckExtKeyUsage: true
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
    disabled: false
  token: ${token}
  ca:
    crt: ${ca}
