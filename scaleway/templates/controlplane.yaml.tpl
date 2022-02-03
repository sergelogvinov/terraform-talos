version: v1alpha1
debug: false
persist: true
machine:
  type: ${type}
  certSANs:
    - "${lbv4}"
    - "${ipv4}"
    - "${ipv4_local}"
    - "${ipv4_vip}"
  kubelet:
    extraArgs:
      node-ip: "${ipv4_local}"
      rotate-server-certificates: true
      node-labels: "${labels}"
    clusterDNS:
      - 169.254.2.53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
    nodeIP:
      validSubnets: ${format("%#v",split(",",nodeSubnets))}
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth1
        addresses:
          - ${ipv4_local}/24
        vip:
          ip: ${ipv4_vip}
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
          - fd00::169:254:2:53/128
    nameservers:
      - 1.1.1.1
      - 8.8.8.8
    kubespan:
      enabled: false
      allowDownPeerBypass: true
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
      options:
        - no_read_workqueue
        - no_write_workqueue
cluster:
  controlPlane:
    endpoint: https://${ipv4_vip}:6443
  discovery:
    enabled: true
    registries:
      service:
        disabled: true
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
    cni:
      name: custom
      urls:
        - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/cilium_result.yaml
  proxy:
    disabled: true
  apiServer:
    certSANs:
      - "${lbv4}"
      - "${ipv4}"
  controllerManager:
    extraArgs:
        node-cidr-mask-size-ipv4: 24
        node-cidr-mask-size-ipv6: 112
  scheduler: {}
  etcd: {}
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
          SCW_DEFAULT_REGION: ${base64encode("fr-par")}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/kubelet-serving-cert-approver.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/metrics-server.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/local-path-storage.yaml
