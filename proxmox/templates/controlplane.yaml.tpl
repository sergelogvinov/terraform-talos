version: v1alpha1
machine:
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
    interfaces:
      - interface: eth1
        vip:
          ip: ${lbv4}
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
  features:
    hostDNS:
      enabled: true
      forwardKubeDNSToHost: false
    kubernetesTalosAPIAccess:
      enabled: true
      allowedRoles:
        - os:reader
        - os:admin
        - os:etcd:backup
      allowedKubernetesNamespaces:
        - kube-system
        - operator-talos
cluster:
  adminKubeconfig:
    certLifetime: 48h0m0s
  controlPlane:
    endpoint: https://${apiDomain}:6443
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
      - ${apiDomain}
  controllerManager:
    image: registry.k8s.io/kube-controller-manager:${version}
    extraArgs:
        controllers: "*,tokencleaner,-node-ipam-controller"
        node-cidr-mask-size-ipv4: "24"
        node-cidr-mask-size-ipv6: "80"
  scheduler:
    image: registry.k8s.io/kube-scheduler:${version}
  etcd:
    advertisedSubnets:
      - ${nodeSubnets[0]}
    listenSubnets:
      - ${nodeSubnets[0]}
  externalCloudProvider:
    enabled: true
  inlineManifests:
    - name: proxmox-cloud-controller-manager
      contents: |-
        apiVersion: v1
        kind: Secret
        type: Opaque
        metadata:
          name: proxmox-cloud-controller-manager
          namespace: kube-system
        data:
          config.yaml: ${base64encode(clusters)}
