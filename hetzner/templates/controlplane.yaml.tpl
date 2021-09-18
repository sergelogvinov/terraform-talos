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
    - "${ipv4_vip}"
    - "${apiDomain}"
  kubelet:
    extraArgs:
      node-ip: "${ipv4_local}"
      rotate-server-certificates: true
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth0
        dhcp: true
        vip:
          ip: ${lbv4}
          hcloud:
            apiToken: ${hcloud_token}
      - interface: eth1
        dhcp: true
        vip:
          ip: ${ipv4_vip}
          hcloud:
            apiToken: ${hcloud_token}
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
          - fd00::169:254:2:53/128
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
cluster:
  controlPlane:
    endpoint: https://${ipv4_vip}:6443
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
      - "${ipv4_vip}"
      - "${apiDomain}"
  controllerManager:
    extraArgs:
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
