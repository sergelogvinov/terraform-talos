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

## Prepare the base image

```sh
cd images
wget https://github.com/siderolabs/talos/releases/download/v1.0.5/openstack-amd64.tar.gz
tar -xzf openstack-amd64.tar.gz

terraform init && terraform apply
```

## Prepare network

* folder prepare

open config file **terraform.tfvars** and add params.

```hcl
```

## Install control plane
