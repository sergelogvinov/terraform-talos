version: v1alpha1
debug: false
persist: true
machine:
  type: controlplane
  certSANs: ${format("%#v",certSANs)}
  kubelet:
    extraArgs:
      node-labels: "${labels}"
      rotate-server-certificates: true
    nodeIP:
      validSubnets: ${format("%#v",nodeSubnets)}
    clusterDNS:
      - 169.254.2.53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth0
        dhcp: true
      - interface: lo
        addresses: ${format("%#v",ipAliases)}
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
    extraHostEntries:
      - ip: ${lbv4}
        aliases:
          - ${apiDomain}
  install:
    wipe: false
  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096
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
        - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/cilium-result.yaml
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
      - ${nodeSubnets[0]}
    listenSubnets:
      - ${nodeSubnets[0]}
    extraArgs:
      election-timeout: "5000"
      heartbeat-interval: "1000"
  inlineManifests:
    - name: azure-cloud-controller-config
      contents: |-
        apiVersion: v1
        kind: Secret
        type: Opaque
        metadata:
          name: azure-cloud-controller-manager
          namespace: kube-system
        data:
          azure.json: ${base64encode(ccm)}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/azure-cloud-controller-manager.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/azure-cloud-node-manager.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/azure-csi-node.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/azure-csi.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/azure-storage.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/kubelet-serving-cert-approver.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/metrics-server.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/local-path-storage.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/coredns-local.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/ingress-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/azure/deployments/ingress-result.yaml
