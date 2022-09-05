version: v1alpha1
debug: false
persist: true
machine:
  type: controlplane
  certSANs:
    - "${lbv4}"
    - "${ipv4}"
    - "${apiDomain}"
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
    nameservers:
      - 1.1.1.1
      - 8.8.8.8
    kubespan:
      enabled: true
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
    registries:
      kubernetes:
        disabled: false
      service:
        disabled: true
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
    cni:
      name: custom
      urls:
        - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/cilium-result.yaml
  proxy:
    disabled: true
  apiServer:
    certSANs:
      - "${lbv4}"
      - "${ipv4}"
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
              - local-path-provisioner
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
          SCW_DEFAULT_REGION: ${base64encode(region)}
          SCW_DEFAULT_ZONE: ${base64encode(zone)}
          SCW_VPC_ID: ${base64encode(vpc_id)}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/scaleway-cloud-controller-manager.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/kubelet-serving-cert-approver.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/metrics-server.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/local-path-storage.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/coredns-local.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/ingress-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/scaleway/deployments/ingress-result.yaml
