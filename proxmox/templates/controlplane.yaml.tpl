machine:
  kubelet:
    extraArgs:
      rotate-server-certificates: true
    clusterDNS:
      - 169.254.2.53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
    nodeIP:
      validSubnets: ${format("%#v",split(",",nodeSubnets))}
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth1
        vip:
          ip: ${ipv4_vip}
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
    extraHostEntries:
      - ip: 127.0.0.1
        aliases:
          - ${apiDomain}
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
    kubernetesTalosAPIAccess:
      enabled: true
      allowedRoles:
        - os:reader
      allowedKubernetesNamespaces:
        - kube-system
cluster:
  controlPlane:
    endpoint: https://${apiDomain}:6443
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
    cni:
      name: custom
      urls:
        - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/proxmox/deployments/cilium-result.yaml
  proxy:
    disabled: true
  controllerManager:
    extraArgs:
        node-cidr-mask-size-ipv4: 24
        node-cidr-mask-size-ipv6: 112
  etcd:
    advertisedSubnets:
      - ${nodeSubnets}
    listenSubnets:
      - ${nodeSubnets}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/main/docs/deploy/cloud-controller-manager.yml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/proxmox/deployments/kubelet-serving-cert-approver.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/proxmox/deployments/metrics-server.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/proxmox/deployments/coredns-local.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/proxmox/deployments/local-path-storage.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/proxmox/deployments/ingress-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/proxmox/deployments/ingress-result.yaml
