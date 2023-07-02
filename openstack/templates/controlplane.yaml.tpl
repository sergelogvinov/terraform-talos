machine:
  certSANs: ${format("%#v",certSANs)}
  kubelet:
    extraArgs:
      node-labels: "${labels}"
      rotate-server-certificates: true
    clusterDNS:
      - 169.254.2.53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
    nodeIP:
      validSubnets: ["${ipv4_local}/32"]
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth1
        addresses:
          - ${ipv4_local}/24
        vip:
          ip: ${ipv4_local_vip}
        routes: ${routes}
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
    certLifetime: 16h0m0s
  controlPlane:
    endpoint: https://${apiDomain}:6443
  clusterName: ${clusterName}
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
    certSANs: ${format("%#v",certSANs)}
  controllerManager:
    extraArgs:
        node-cidr-mask-size-ipv4: 24
        node-cidr-mask-size-ipv6: 112
  scheduler: {}
  etcd:
    advertisedSubnets:
      - ${ipv4_local}/32
    listenSubnets:
      - ${ipv4_local}/32
    extraArgs:
      election-timeout: "5000"
      heartbeat-interval: "1000"
  inlineManifests:
    - name: openstack-cloud-controller-config
      contents: |-
        apiVersion: v1
        kind: Secret
        type: Opaque
        metadata:
          name: openstack-cloud-controller-manager
          namespace: kube-system
        data:
          cloud.conf: ${base64encode(occm)}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/talos-cloud-controller-manager-result.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/openstack-cloud-controller-manager-result.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/openstack-cinder-csi-result.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/metrics-server-result.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/local-path-storage-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/local-path-storage-result.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/coredns-local.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/ingress-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/ingress-result.yaml
