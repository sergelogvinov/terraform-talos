version: v1alpha1
debug: false
persist: true
machine:
  type: ${type}
  certSANs:
    - "${lbv4}"
    - "${ipv4}"
    - "${ipv6}"
    - "${ipv4_local}"
    - "${ipv4_local_vip}"
    - "${apiDomain}"
  kubelet:
    extraArgs:
      node-ip: "${ipv4_local}"
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
      - interface: eth1
        addresses:
          - ${ipv4_local}/24
        vip:
          ip: ${ipv4_local_vip}
        routes: ${indent(10,routes)}
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
    extraHostEntries:
      - ip: ${ipv4_local_vip}
        aliases:
          - ${apiDomain}
  install:
    wipe: false
  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096
cluster:
  id: ${clusterID}
  secret: ${clusterSecret}
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
        - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/cilium-result.yaml
  proxy:
    disabled: true
  apiServer:
    certSANs:
      - "${lbv4}"
      - "${ipv4}"
      - "${ipv6}"
      - "${ipv4_local}"
      - "${ipv4_local_vip}"
      - "${apiDomain}"
  controllerManager:
    extraArgs:
        node-cidr-mask-size-ipv4: 24
        node-cidr-mask-size-ipv6: 112
  scheduler: {}
  etcd:
    subnet: ${nodeSubnets[0]}
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
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/openstack-cloud-controller-manager.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/kubelet-serving-cert-approver.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/metrics-server.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/local-path-storage.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/coredns-local.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/ingress-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/ingress-result.yaml
