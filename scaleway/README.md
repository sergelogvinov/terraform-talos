# Terraform example for Scaleway

Local utilities

* terraform
* talosctl
* kubectl
* yq

## Kubernetes addons

* [cilium](https://github.com/cilium/cilium) 1.11.1
* [kubelet-serving-cert-approver](https://github.com/alex1989hu/kubelet-serving-cert-approver)
* [metrics-server](https://github.com/kubernetes-sigs/metrics-server) 0.5.0
* [rancher.io/local-path](https://github.com/rancher/local-path-provisioner) 0.0.19

## Prepare the base image

Use [packer](../system_os/scaleway) to upload the Talos image.

## Install control plane

Generate the default talos config

```shell
make create-lb create-config create-templates
```

open config file **terraform.tfvars** and add params

```hcl
# counts and type of kubernetes master nodes
controlplane = {
    count = 1,
    type  = "DEV1-S"
}

instances = {
  web_count            = 1,
  web_instance_type    = "DEV1-S",
  worker_count         = 1,
  worker_instance_type = "DEV1-S",
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
