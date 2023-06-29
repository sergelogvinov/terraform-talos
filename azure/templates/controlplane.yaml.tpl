machine:
  certSANs: ${format("%#v",certSANs)}
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
    extraArgs:
      node-labels: "${labels}"
      rotate-server-certificates: true
    clusterDNS:
      - 169.254.2.53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
    nodeIP:
      validSubnets: ${format("%#v",nodeSubnets)}
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth0
        dhcp: true
        dhcpOptions:
          ipv6: true
        routes:
          - network: ::/0
            gateway: fe80::1234:5678:9abc
%{if length(ipAliases) > 0 }
      - interface: lo
        addresses: ${format("%#v",ipAliases)}
%{endif}
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
%{if acrRepo != "" }
  registries:
    config:
      ${acrRepo}:
        auth:
          username: ${acrUsername}
          password: ${acrPassword}
%{endif}
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
    image: ${ repository }/kube-apiserver:${ version }
    certSANs: ${format("%#v",certSANs)}
  controllerManager:
    image: ${ repository }/kube-controller-manager:${ version }
    extraArgs:
        node-cidr-mask-size-ipv4: 24
        node-cidr-mask-size-ipv6: 112
  scheduler:
    image: ${ repository }/kube-scheduler:${ version }
  etcd:
    advertisedSubnets:
      - ${nodeSubnets[0]}
    listenSubnets:
      - ${nodeSubnets[0]}
    extraArgs:
      election-timeout: "5000"
      heartbeat-interval: "1000"
  inlineManifests:
    - name: azure-managed-identity
      contents: |-
        apiVersion: v1
        kind: Secret
        type: Opaque
        metadata:
          name: azure-managed-identity
          namespace: kube-system
        data:
          azure.json: ${base64encode(ccm)}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/talos-cloud-controller-manager-result.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/azure-cloud-controller-manager.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/azure-autoscaler-result.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/azuredisk-csi-driver-result.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/azuredisk-storage.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/metrics-server-result.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/local-path-storage-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/local-path-storage-result.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/coredns-local.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/ingress-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/ingress-result.yaml
