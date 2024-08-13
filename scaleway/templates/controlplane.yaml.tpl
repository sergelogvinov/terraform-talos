machine:
  certSANs:
    - ${lbv4}
    - ${apiDomain}
  kubelet:
    image: ghcr.io/siderolabs/kubelet:${version}
    extraArgs:
      rotate-server-certificates: true
    clusterDNS:
      - 169.254.2.53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
    nodeIP:
      validSubnets: ${format("%#v",nodeSubnets)}
  network:
    hostname: ${name}
    interfaces:
      - interface: eth1
        dhcp: true
        dhcpOptions:
          routeMetric: 2048
        addresses:
          - ${ipv4_local}
        vip:
          ip: ${ipv4_vip}
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
    kubespan:
      enabled: false
      allowDownPeerBypass: true
      filters:
        endpoints:
          - 0.0.0.0/0
          - "!${ipv4_vip}/32"
          - "!${ipv4_local}/32"
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
    certLifetime: 48h0m0s
  controlPlane:
    endpoint: https://${apiDomain}:6443
  discovery:
    enabled: false
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
    cni:
      name: none
  proxy:
    disabled: true
  apiServer:
    image: registry.k8s.io/kube-apiserver:${version}
    resources:
      requests:
        cpu: 500m
        memory: 1Gi
    certSANs:
      - ${lbv4}
      - ${apiDomain}
  controllerManager:
    image: registry.k8s.io/kube-controller-manager:${version}
    extraArgs:
        node-cidr-mask-size-ipv4: "24"
        node-cidr-mask-size-ipv6: "112"
  scheduler:
    image: registry.k8s.io/kube-scheduler:${version}
  etcd:
    advertisedSubnets:
      - ${nodeSubnets[0]}
    listenSubnets:
      - ${nodeSubnets[0]}
  inlineManifests:
    - name: scaleway-secret
      contents: |-
        apiVersion: v1
        kind: Secret
        type: Opaque
        metadata:
          name: scaleway-secret
          namespace: kube-system
        data:
          SCW_ACCESS_KEY: ${base64encode(access)}
          SCW_SECRET_KEY: ${base64encode(secret)}
          SCW_DEFAULT_PROJECT_ID:  ${base64encode(project_id)}
          SCW_DEFAULT_REGION: ${base64encode(region)}
          SCW_DEFAULT_ZONE: ${base64encode(zone)}
          SCW_VPC_ID: ${base64encode(vpc_id)}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/scaleway-cloud-controller-manager.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/local-path-storage-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/local-path-storage-result.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/coredns-local.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/ingress-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/ingress-result.yaml
