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
      node-ip: "${ipv4}"
      cloud-provider: external
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
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
          - fd00::169:254:2:53/128
  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096
    net.ipv4.tcp_keepalive_time: 600
    net.ipv4.tcp_keepalive_intvl: 60
    fs.inotify.max_user_instances: 256
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
      options:
        - no_read_workqueue
        - no_write_workqueue
  registries:
    mirrors:
      docker.io:
        endpoints:
          - https://registry-1.docker.io
cluster:
  controlPlane:
    endpoint: https://${lbv4}:6443
  clusterName: ${clusterName}
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
  token: ${token}
  ca:
    crt: ${ca}
