version: v1alpha1
debug: false
persist: true
machine:
  certSANs:
    - ${lbv4}
    - ${lbv4_local}
    - ${apiDomain}
  kubelet:
    extraArgs:
      rotate-server-certificates: true
    nodeIP:
      validSubnets: ${format("%#v",split(",",nodeSubnets))}
  network:
    hostname: "${name}"
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
  time:
    servers:
      - 169.254.169.254
cluster:
  controlPlane:
    endpoint: https://${lbv4_local}:6443
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
    cni:
      name: custom
      urls:
        - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/oracle/deployments/cilium_result.yaml
  proxy:
    disabled: true
  apiServer:
    certSANs:
      - ${lbv4}
      - ${lbv4_local}
      - ${apiDomain}
  controllerManager:
    extraArgs:
        node-cidr-mask-size-ipv4: 24
        node-cidr-mask-size-ipv6: 112
  scheduler: {}
  etcd: {}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/oracle/deployments/kubelet-serving-cert-approver.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/oracle/deployments/metrics-server.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/oracle/deployments/local-path-storage.yaml
