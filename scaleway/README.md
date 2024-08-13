# Terraform example for Scaleway

Local utilities

* terraform
* talosctl
* kubectl
* yq

## Kubernetes addons

* [cilium](https://github.com/cilium/cilium) 1.15.7
* [metrics-server](https://github.com/kubernetes-sigs/metrics-server) 3.12.1
* [rancher.io/local-path](https://github.com/rancher/local-path-provisioner) 0.0.26
* [talos CCM](https://github.com/siderolabs/talos-cloud-controller-manager) edge, controller: `cloud-node`.
* [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) 4.11.1

## Prepare the base image

Use [packer](images/) to upload the Talos image.

## Install control plane

Generate the default talos config

```shell
make create-config create-templates
```

open config file **terraform.tfvars** and add params

```hcl
# counts and type of kubernetes master nodes
controlplane = {
    count = 1,
    type  = "COPARM1-2C-8G"
}

instances = {
    "all" = {
      version = "v1.30.2"
    },
    "fr-par-2" = {
      web_count    = 1,
      web_type     = "COPARM1-2C-8G",
      worker_count = 1,
      worker_type  = "COPARM1-2C-8G",
    },
}
```

Bootstrap all the infrastructure

```shell
make create-infrastructure

# see terraform output: controlplane_config
talosctl apply-config --insecure --nodes $IP --config-patch @_cfgs/controlplane-1.yaml --file _cfgs/controlplane.yaml

make bootstrap
make system
```
