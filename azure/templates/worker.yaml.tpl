version: v1alpha1
debug: false
persist: true
machine:
  type: worker
  token: ${tokenMachine}
  ca:
    crt: ${caMachine}
%{if repository != "registry.k8s.io"}
  files:
    - content: |
        [plugins]
          [plugins."io.containerd.grpc.v1.cri"]
            sandbox_image = "${ repository }/pause:3.8"
      path: /etc/cri/conf.d/20-customization.part
      op: create
%{endif}
  kubelet:
    image: %{if repository == "registry.k8s.io"}ghcr.io/siderolabs%{else}${ repository }%{endif}/kubelet:${ version }
    defaultRuntimeSeccompProfileEnabled: true
    extraArgs:
      cloud-provider: external
      rotate-server-certificates: true
      node-labels: "${labels}"
    clusterDNS:
      - 169.254.2.53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
    nodeIP:
      validSubnets: ${format("%#v",nodeSubnets)}
  network:
    interfaces:
      - interface: eth0
        dhcp: true
        dhcpOptions:
          ipv6: true
        routes:
          - network: ::/0
            gateway: fe80::1234:5678:9abc
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
%{if lbv4 != "" }
    extraHostEntries:
      - ip: ${lbv4}
        aliases:
          - ${apiDomain}
%{endif}
  time:
    servers:
      - time.cloudflare.com
  install:
    wipe: false
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
  features:
    rbac: true
    stableHostname: true
    apidCheckExtKeyUsage: true
%{if acrRepo != "" }
  registries:
    config:
      ${acrRepo}:
        auth:
          username: ${acrUsername}
          password: ${acrPassword}
%{endif}
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
