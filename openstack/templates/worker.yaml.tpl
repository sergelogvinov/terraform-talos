version: v1alpha1
debug: false
persist: true
machine:
  type: worker
  token: ${tokenMachine}
  ca:
    crt: ${caMachine}
  kubelet:
    extraArgs:
      rotate-server-certificates: true
      cloud-provider: external
      node-labels: "${labels}"
    nodeIP:
      validSubnets: ${format("%#v",split(",",nodeSubnets))}
    clusterDNS:
      - 169.254.2.53
      - fd00::169:254:2:53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
  network:
    hostname: "${name}"
    interfaces:
      - interface: ${iface}
        dhcp: true
        routes: ${indent(10,routes)}
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
          - fd00::169:254:2:53/128
    extraHostEntries:
      - ip: ${lbv4}
        aliases:
          - ${apiDomain}
  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096
  install:
    wipe: false
cluster:
  id: ${clusterID}
  secret: ${clusterSecret}
  controlPlane:
    endpoint: https://${lbv4}:6443
  clusterName: ${clusterName}
  network:
    dnsDomain: ${domain}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
  proxy:
    disabled: true
  token: ${token}
  ca:
    crt: ${ca}
