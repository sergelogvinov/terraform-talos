# Talos on OVH Cloud

This terraform example to install Talos on [OpenStack](https://www.ovhcloud.com/en-ie/) with IPv4/IPv6 support.

Tested on openstack version - [Stein](https://docs.openstack.org/stein/index.html)
* Nova
* Glance
* Neutron
* Cinder

## Local utilities

* terraform
* talosctl
* kubectl
* yq

# Network diagram

<img src="/img/openstack.png" width="500px">

## Kubernetes addons

* [cilium](https://github.com/cilium/cilium) 1.11.4
* [kubelet-serving-cert-approver](https://github.com/alex1989hu/kubelet-serving-cert-approver)
* [metrics-server](https://github.com/kubernetes-sigs/metrics-server) 0.5.0
* [rancher.io/local-path](https://github.com/rancher/local-path-provisioner) 0.0.19
* [openstack-cloud-controller-manage](https://github.com/sergelogvinov/cloud-provider-openstack)
* [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) 4.1.1

## Upload the talos image

Create the config file **images/terraform.tfvars** and add params.

```hcl
# Body of images/terraform.tfvars

# Regions to use
regions          = ["GRA7", "GRA9"]
```

```shell
cd images
wget https://github.com/siderolabs/talos/releases/download/v1.0.5/openstack-amd64.tar.gz
tar -xzf openstack-amd64.tar.gz

terraform init && terraform apply
```

## Prepare network

Create the config file **prepare/terraform.tfvars** and add params.

```hcl
# Body of prepare/terraform.tfvars

# Regions to use
regions          = ["GRA7", "GRA9"]
```

```shell
make create-network
```

## Prepare configs

Generate the default talos config

```shell
make create-config create-templates
```

Create the config file **terraform.tfvars** and add params.

```hcl
# Body of terraform.tfvars

# OCCM Credits
ccm_username = "openstack-username"
ccm_password = "openstack-password"

# Number of kubernetes controlplane by zones
controlplane = {
  "GRA9" = {
    count         = 1,
    instance_type = "d2-4",
  },
}

# Number of kubernetes nodes by zones
instances = {
  "GRA9" = {
    web_count            = 1,
    web_instance_type    = "d2-2",
    worker_count         = 1,
    worker_instance_type = "d2-2"
  },
}

```

## Bootstrap controlplane

```shell
make create-controlplane
```

## Download configs

```shell
make create-kubeconfig
```

## Deploy all other instances

```shell
make create-infrastructure
```

# Known Issues

* [OCCM](https://github.com/kubernetes/cloud-provider-openstack/blob/master/docs/openstack-cloud-controller-manager/using-openstack-cloud-controller-manager.md): Openstack cloud controller manage does not work well with zones.
  It will delete nodes from another zone (because it cannot find the node in the cloud provider).
  References:
  * https://github.com/kubernetes/cloud-provider/issues/35
  * https://github.com/kubernetes/kubernetes/pull/73171
  * https://github.com/ovh/public-cloud-roadmap/issues/22

  Solution:

  Use [OCCM](https://github.com/sergelogvinov/cloud-provider-openstack/tree/multi-ccm) from my fork. You can run many **occm** with different key ```--leader-elect-resource-name=cloud-controller-manager-$region```

  It creates the ProviderID with region name inside, such ```openstack://$region/$id```

* [CSI](https://github.com/kubernetes/cloud-provider-openstack/blob/master/docs/cinder-csi-plugin/using-cinder-csi-plugin.md): Openstack cinder cannot work in different zones.
  You need to install two o more daemonsets for each zone.
* [NodeAutoscaller](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/magnum) can work only with openstack magnum.
  Unfortunately I do not have it.
