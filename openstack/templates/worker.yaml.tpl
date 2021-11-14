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
      cloud-provider: external
      rotate-server-certificates: true
      node-labels: "${labels}"
    nodeIP:
      validSubnets: ${format("%#v",split(",",nodeSubnets))}
    clusterDNS:
      - 169.254.2.53
  network:
    hostname: "${name}"
    interfaces:
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
          - fd00::169:254:2:53/128
  sysctls:
    net.core.somaxconn: 65535
    net.core.netdev_max_backlog: 4096
  install:
    wipe: false
cluster:
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
