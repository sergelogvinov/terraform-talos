version: v1alpha1
debug: false
persist: true
machine:
  type: ${type}
  certSANs:
    - "${lbv4}"
    - "${ipv4}"
    - "${ipv4_local}"
    - "${ipv4_local_vip}"
    - "${apiDomain}"
  kubelet:
    extraArgs:
      node-ip: "${ipv4_local}"
      node-labels: "${labels}"
      rotate-server-certificates: true
    nodeIP:
      validSubnets: ${format("%#v",split(",",nodeSubnets))}
    clusterDNS:
      - 169.254.2.53
      - fd00::169:254:2:53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth0
        dhcp: true
        addresses:
          - ${ipv6}/56
      - interface: eth1
        addresses:
          - ${ipv4_local}/24
        vip:
          ip: ${ipv4_local_vip}
        routes:
          - network: ${ipv4_local_network}
            gateway: ${ipv4_local_gw}
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
          - fd00::169:254:2:53/128
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
  controlPlane:
    endpoint: https://${ipv4_local_vip}:6443
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
    cni:
      name: custom
      urls:
        - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/cilium_result.yaml
  proxy:
    disabled: true
  apiServer:
    certSANs:
      - "${lbv4}"
      - "${ipv4}"
      - "${ipv4_local}"
      - "${ipv4_local_vip}"
      - "${apiDomain}"
  controllerManager:
    extraArgs:
        node-cidr-mask-size-ipv4: 24
        node-cidr-mask-size-ipv6: 112
  scheduler: {}
  etcd: {}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/kubelet-serving-cert-approver.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/metrics-server.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/local-path-storage.yaml
