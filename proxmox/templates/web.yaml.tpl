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
      node-labels: ${labels}
    extraConfig:
      serverTLSBootstrap: true
      imageGCHighThresholdPercent: 70
      imageGCLowThresholdPercent: 50
      shutdownGracePeriod: 60s
      topologyManagerPolicy: best-effort
      topologyManagerScope: container
      cpuManagerPolicy: static
      allowedUnsafeSysctls: [net.core.somaxconn]
    clusterDNS:
      - 169.254.2.53
      - ${clusterDns}
    nodeIP:
      validSubnets: ${format("%#v",nodeSubnets)}
  network:
    interfaces:
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
    extraHostEntries:
      - ip: ${lbv4}
        aliases:
          - ${apiDomain}
  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096
    net.ipv4.tcp_keepalive_intvl: 60
    net.ipv4.tcp_keepalive_time: 600
    net.ipv4.tcp_fin_timeout: 10
    net.ipv4.tcp_tw_reuse: 1
    vm.max_map_count: 128000
  install:
    wipe: true
    extraKernelArgs:
      - talos.dashboard.disabled=1
%{ for arg in kernelArgs ~}
      - ${arg}
%{ endfor ~}
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
    kubePrism:
      enabled: true
      port: 7445
    hostDNS:
      enabled: false
cluster:
  id: ${clusterID}
  secret: ${clusterSecret}
  controlPlane:
    endpoint: https://${apiDomain}:6443
  clusterName: ${clusterName}
  discovery:
    enabled: false
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
  proxy:
    disabled: true
  token: ${token}
  ca:
    crt: ${ca}
