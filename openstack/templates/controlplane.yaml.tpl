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
      node-labels: "${labels}"
    clusterDNS:
      - 169.254.2.53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
    nodeIP:
      validSubnets: ${format("%#v",nodeSubnets)}
  network:
    hostname: "${name}"
    interfaces:
      - interface: eth1
        addresses:
          - ${ipv4_local}/24
        vip:
          ip: ${ipv4_local_vip}
        routes: ${routes}
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
      - ${nodeSubnets[0]}
    listenSubnets:
      - ${nodeSubnets[0]}
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
      - https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/main/docs/deploy/cloud-controller-manager.yml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/openstack-cloud-controller-manager.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/kubelet-serving-cert-approver.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/metrics-server.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/local-path-storage.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/coredns-local.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/ingress-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/ingress-result.yaml
