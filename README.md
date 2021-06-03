# Terraform examples

Local utilities

* terraform
* talosctl
* kubectl
* yq

# Talos on Hetzner Cloud

This terraform example install Talos on [HCloud](https://www.hetzner.com/cloud) with IPv4/IPv6 support.

## Kubernetes addons

* [cilium](https://github.com/cilium/cilium) 1.10.0
* [kubelet-serving-cert-approver](https://github.com/alex1989hu/kubelet-serving-cert-approver)
* [metrics-server](https://github.com/kubernetes-sigs/metrics-server) 0.5.0
* [rancher.io/local-path](https://github.com/rancher/local-path-provisioner) 0.0.19
* [hcloud-cloud-controller-manage](https://github.com/hetznercloud/hcloud-cloud-controller-manager) v1.10.0

## Prepare the base image

First, prepare variables to your environment

```shell
export TF_VAR_hcloud_token=KEY
```

Terraform will run the VM in recovery mode, replace the base image and take a snapshote. Do not run terraform destroy after. It will delete the snapshot.

```shell
make prepare-image
```

## Install control plane

Generate the default talos config

```shell
make create-config
```

open config file **terraform.tfvars** and add params

```hcl
# counts and type of kubernetes master nodes
controlplane = {
    count = 1,
    type  = "cpx11"
}

# regions to use
regions = ["nbg1", "fsn1", "hel1"]

# counts and type of worker nodes by redion
instances = {
    "nbg1" = {
      web_count            = 1,
      web_instance_type    = "cx11",
      worker_count         = 1,
      worker_instance_type = "cx11",
    },
    "fsn1" = {
      web_count            = 1,
      web_instance_type    = "cx11",
      worker_count         = 1,
      worker_instance_type = "cx11",
    }
    "hel1" = {
      web_count            = 1,
      web_instance_type    = "cx11",
      worker_count         = 1,
      worker_instance_type = "cx11",
    }
}
```

And deploy the kubernetes master nodes

```shell
make create-controlplane
```

Then deploy all other instances

```shell
make create-infrastructure
```
