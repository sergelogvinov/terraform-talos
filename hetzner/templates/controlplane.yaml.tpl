version: v1alpha1
debug: false
persist: true
machine:
  type: ${type}
  certSANs:
    - "${lbv4}"
    - "${lbv6}"
    - "${lbv4_local}"
    - "${ipv4_local}"
  kubelet:
    extraArgs:
      node-ip: "${ipv4_local}"
      rotate-server-certificates: true
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth0
        dhcp: true
      - interface: eth1
        dhcp: true
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
          - fd00::169:254:2:53/128
  install:
    disk: /dev/sda
    bootloader: true
    wipe: false
    extraKernelArgs:
      - elevator=noop
  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096
  systemDiskEncryption:
    ephemeral:
      provider: luks2
      keys:
        - nodeID: {}
          slot: 0
cluster:
  controlPlane:
    endpoint: https://${lbv4}:6443
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("[%s]",podSubnets)}
    serviceSubnets: ${format("[%s]",serviceSubnets)}
    cni:
      name: custom
      urls:
        - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/cilium_result.yaml
  proxy:
    disabled: true
    mode: ipvs
  apiServer:
    certSANs:
      - "${lbv4}"
      - "${lbv6}"
      - "${lbv4_local}"
      - "${ipv4_local}"
    extraArgs:
        feature-gates: IPv6DualStack=true
  controllerManager:
    extraArgs:
        feature-gates: IPv6DualStack=true
        node-cidr-mask-size-ipv4: 24
        node-cidr-mask-size-ipv6: 112
  scheduler: {}
  etcd: {}
  inlineManifests:
    - name: hcloud-secret
      contents: |-
        apiVersion: v1
        kind: Secret
        type: Opaque
        metadata:
          name: hcloud
          namespace: kube-system
        data:
          network: ${base64encode(hcloud_network)}
          token: ${base64encode(hcloud_token)}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/hcloud-cloud-controller-manager.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/kubelet-serving-cert-approver.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/metrics-server.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/local-path-storage.yaml
