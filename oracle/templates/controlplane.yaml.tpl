version: v1alpha1
debug: false
persist: true
machine:
  type: controlplane
  certSANs:
    - ${lbv4}
    - ${lbv4_local}
    - ${apiDomain}
  features:
    kubernetesTalosAPIAccess:
      enabled: true
      allowedRoles:
        - os:reader
      allowedKubernetesNamespaces:
        - kube-system
  kubelet:
    extraArgs:
      rotate-server-certificates: true
      node-labels: ${labels}
    clusterDNS:
      - 169.254.2.53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
    nodeIP:
      validSubnets: ${format("%#v",split(",",nodeSubnets))}
  network:
    hostname: "${name}"
    interfaces:
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
    extraHostEntries:
      - ip: ${lbv4_local}
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
  time:
    servers:
      - 169.254.169.254
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
        - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/oracle/deployments/cilium_result.yaml
  proxy:
    disabled: true
  apiServer:
    certSANs:
      - ${lbv4}
      - ${lbv4_local}
      - ${apiDomain}
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
    - name: cloud-provider.yaml
      contents: |-
        apiVersion: v1
        kind: Secret
        type: Opaque
        metadata:
          name: oci-cloud-controller-manager
          namespace: kube-system
        data:
          cloud-provider.yaml: ${ccm}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/main/docs/deploy/cloud-controller-manager.yml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/oracle/deployments/oci-cloud-controller-manager.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/oracle/deployments/kubelet-serving-cert-approver.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/oracle/deployments/metrics-server.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/oracle/deployments/local-path-storage.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/oracle/deployments/coredns-local.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/oracle/deployments/ingress-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/oracle/deployments/ingress_result.yaml
