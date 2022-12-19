version: v1alpha1
debug: false
persist: true
machine:
  type: controlplane
  certSANs:
    - "${lbv4}"
    - "${lbv6}"
    - "${lbv4_local}"
    - "${ipv4_local}"
    - "${ipv4_vip}"
    - "${apiDomain}"
  features:
    kubernetesTalosAPIAccess:
      enabled: true
      allowedRoles:
        - os:reader
      allowedKubernetesNamespaces:
        - kube-system
  kubelet:
    extraArgs:
      node-ip: "${ipv4_local}"
      rotate-server-certificates: true
    clusterDNS:
      - 169.254.2.53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
    nodeIP:
      validSubnets: ${format("%#v",split(",",nodeSubnets))}
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth0
        dhcp: true
        vip:
          ip: ${lbv4}
          hcloud:
            apiToken: ${hcloud_token}
      - interface: eth1
        dhcp: true
        vip:
          ip: ${ipv4_vip}
          hcloud:
            apiToken: ${hcloud_token}
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
    kubespan:
      enabled: false
      allowDownPeerBypass: true
    extraHostEntries:
      - ip: ${ipv4_vip}
        aliases:
          - ${apiDomain}
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
  id: ${clusterID}
  secret: ${clusterSecret}
  controlPlane:
    endpoint: https://${apiDomain}:6443
  clusterName: ${clusterName}
  discovery:
    enabled: true
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
    cni:
      name: custom
      urls:
        - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/cilium-result.yaml
  proxy:
    disabled: true
    mode: ipvs
  apiServer:
    certSANs:
      - "${lbv4}"
      - "${lbv6}"
      - "${lbv4_local}"
      - "${ipv4_local}"
      - "${ipv4_vip}"
      - "${apiDomain}"
    admissionControl:
      - name: PodSecurity
        configuration:
          apiVersion: pod-security.admission.config.k8s.io/v1alpha1
          defaults:
            audit: restricted
            audit-version: latest
            enforce: baseline
            enforce-version: latest
            warn: restricted
            warn-version: latest
          exemptions:
            namespaces:
              - kube-system
              - ingress-nginx
              - monitoring
              - local-path-storage
              - local-lvm
            runtimeClasses: []
            usernames: []
          kind: PodSecurityConfiguration
  controllerManager:
    extraArgs:
        node-cidr-mask-size-ipv4: 24
        node-cidr-mask-size-ipv6: 112
  scheduler: {}
  etcd:
    advertisedSubnets:
      - ${nodeSubnets}
    listenSubnets:
      - ${nodeSubnets}
  inlineManifests:
    - name: hcloud-secret
      contents: |-
        apiVersion: v1
        kind: Secret
        type: Opaque
        metadata:
          name: hcloud
          namespace: kube-system
        data:
          network: ${base64encode(hcloud_network)}
          token: ${base64encode(hcloud_token)}
          user: ${base64encode(robot_user)}
          password: ${base64encode(robot_password)}
          image: ${base64encode(hcloud_image)}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/main/docs/deploy/cloud-controller-manager.yml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/hcloud-cloud-controller-manager.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/hcloud-csi.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/kubelet-serving-cert-approver.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/metrics-server.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/local-path-storage.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/coredns-local.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/ingress-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/hetzner/deployments/ingress-result.yaml
