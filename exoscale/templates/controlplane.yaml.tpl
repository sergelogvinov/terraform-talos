machine:
  kubelet:
    extraArgs:
      node-labels: "${labels}"
      rotate-server-certificates: true
    clusterDNS:
      - 169.254.2.53
      - ${cidrhost(split(",",serviceSubnets)[0], 10)}
    nodeIP:
      validSubnets:
        - ${nodeSubnets}
  network:
    interfaces:
      - interface: eth1
        dhcp: true
        vip:
          ip: ${ipv4_local_vip}
      - interface: dummy0
        addresses:
          - 169.254.2.53/32
    kubespan:
      enabled: false
    extraHostEntries:
      - ip: ${ipv4_local_vip}
        aliases:
          - ${apiDomain}
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
  discovery:
    enabled: false
  network:
    dnsDomain: ${domain}
    podSubnets: ${format("%#v",split(",",podSubnets))}
    serviceSubnets: ${format("%#v",split(",",serviceSubnets))}
    cni:
      name: custom
      urls:
        - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/exoscale/deployments/cilium-result.yaml
  proxy:
    disabled: true
  apiServer:
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
            runtimeClasses: []
            usernames: []
          kind: PodSecurityConfiguration
  controllerManager:
    extraArgs:
        node-cidr-mask-size-ipv4: 24
        node-cidr-mask-size-ipv6: 112
  etcd:
    advertisedSubnets:
      - ${nodeSubnets}
    listenSubnets:
      - ${nodeSubnets}
  inlineManifests:
    - name: exoscale-secret
      contents: |-
        apiVersion: v1
        kind: Secret
        type: Opaque
        metadata:
          name: exoscale-secret
          namespace: kube-system
        data:
          EXOSCALE_API_KEY: ${base64encode(key)}
          EXOSCALE_API_SECRET: ${base64encode(secret)}
          EXOSCALE_ZONE: ${base64encode(zone)}
  externalCloudProvider:
    enabled: true
    manifests:
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/exoscale/deployments/metrics-server.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/exoscale/deployments/local-path-storage.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/exoscale/deployments/coredns-local.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/exoscale/deployments/ingress-ns.yaml
      - https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/exoscale/deployments/ingress-result.yaml
