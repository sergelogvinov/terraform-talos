machine:
  certSANs:
    - "${lbv4}"
    - "${lbv6}"
    - "${lbv4_local}"
    - "${ipv4_local}"
    - "${ipv4_vip}"
    - "${apiDomain}"
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
  adminKubeconfig:
    certLifetime: 8h0m0s
  controlPlane:
    endpoint: https://${apiDomain}:6443
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
    cni:
      name: custom
      urls:
        - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/cilium-result.yaml
  proxy:
    disabled: true
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
  etcd:
    advertisedSubnets:
      - ${nodeSubnets}
    listenSubnets:
      - ${nodeSubnets}
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
          user: ${base64encode(robot_user)}
          password: ${base64encode(robot_password)}
          image: ${base64encode(hcloud_image)}
          sshkey: ${base64encode(hcloud_sshkey)}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/talos-cloud-controller-manager-result.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/hcloud-cloud-controller-manager.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/hcloud-csi.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/metrics-server-result.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/local-path-storage-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/local-path-storage-result.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/coredns-local.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/ingress-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/ingress-result.yaml
