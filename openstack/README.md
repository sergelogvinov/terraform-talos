# Talos on OVH Cloud

This terraform example to install Talos on [OpenStack](https://www.ovhcloud.com/en-ie/) with IPv4/IPv6 support.

Tested on openstack version - [Stein](https://docs.openstack.org/stein/index.html)
* Nova
* Glance
* Neutron
* Cinder

Local utilities

* terraform
* talosctl
* kubectl
* yq

## Kubernetes addons

* [cilium](https://github.com/cilium/cilium) 1.11.4
* [kubelet-serving-cert-approver](https://github.com/alex1989hu/kubelet-serving-cert-approver)
* [metrics-server](https://github.com/kubernetes-sigs/metrics-server) 0.5.0
* [rancher.io/local-path](https://github.com/rancher/local-path-provisioner) 0.0.19
* [openstack-cloud-controller-manage](https://github.com/sergelogvinov/cloud-provider-openstack)

## Upload the talos image

Create the config file **images/terraform.tfvars** and add params.

```hcl
# Regions to use
regions          = ["GRA7", "GRA9"]
```

```sh
cd images
wget https://github.com/siderolabs/talos/releases/download/v1.0.5/openstack-amd64.tar.gz
tar -xzf openstack-amd64.tar.gz

terraform init && terraform apply
```

## Prepare network

Create the config file **prepare/terraform.tfvars** and add params.

```hcl
# Regions to use
regions          = ["GRA7", "GRA9"]
```

```sh
make create-network
```

## Prepare configs

Generate the default talos config

```shell
make create-config create-templates
```

Create the config file **terraform.tfvars** and add params.

```hcl
ccm_username = "openstack-username"
ccm_password = "openstack-password"

controlplane = {
  "GRA9" = {
    count         = 1,
    instance_type = "d2-4",
  },
}

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

```sh
make create-controlplane
```

## Download configs

```sh
make create-kubeconfig
```

## Deploy all other instances

```shell
make create-infrastructure
```
