# Proxmox

It was tested on Proxmox version 7.4-3

Local utilities

* terraform
* talosctl
* kubectl
* sops
* yq

## Kubernetes addons

* [cilium](https://github.com/cilium/cilium) 1.16.3
* [metrics-server](https://github.com/kubernetes-sigs/metrics-server) 0.7.2
* [Talos CCM](https://github.com/siderolabs/talos-cloud-controller-manager) edge, controller: `cloud-node`.
Talos CCM labels the nodes, and approve node server certificate signing request.
* [Proxmox CCM](https://github.com/sergelogvinov/proxmox-cloud-controller-manager) edge, controller: `cloud-node-lifecycle`.
Proxmox CCM deletes the kubernetes node resource if they was deleted in Proxmox.
* [Proxmox CSI](https://github.com/sergelogvinov/proxmox-csi-plugin)
Allows you to mount Proxmox disk to the pods.

All deployments use nodeSelector, controllers runs on control-plane, all other on workers.

# Steps

* [Prepare](prepare/) - (optional) it uses ansible to configure the proxmox node/cluster.
* [Images](images/) - upload the Talos OS image to the Proxmox storage.
* [Init](init/) - creates the roles to Proxmox CCM/CSI.
* Bootstrap cluster

## Images

First we need to upload the talos OS image to the Proxmox host machine.
If you do not have shared storage, you need to upload image to each machine.

Follow this link [README](images/README.md) to make it.

## Init

Create Proxmox role and accounts.
This credentials will use by Proxmox CCM and CSI.

```shell
cd init
terraform init -upgrade
terraform apply
```

## Bootstrap cluster

Terraform will create the Talos machine config and upload it to the Proxmox server, but only for worker nodes.
It will also create a metadata file, which is a very important file that contains information such as region, zone, and providerID.
This metadata is used by the Talos CCM to label the nodes and it also required by the Proxmox CCM/CSI.

Control-plane machine config uploads by command `talosctl apply-config`, because I do not want to store all kubernetes secrets in proxmox server.
Terraform shows you command to launch.

VM config looks like:

```yaml
# Worker node /etc/pve/qemu-server/worker-11.conf
cpu: host
cicustom: user=local:snippets/worker.yaml,meta=local:snippets/worker-11.metadata.yaml
ipconfig0: ...
net0: ...
```

Metadata file looks like:

```yaml
# /var/lib/vz/snippets/worker-11.metadata.yaml
hostname: worker-11
instance-id: 1050
instance-type: 2VCPU-4GB
provider-id: proxmox://cluster-1/1050
region: cluster-1
zone: node1
```

Worker machine config:

```yaml
# /var/lib/vz/snippets/worker.yaml
version: v1alpha1
debug: false
persist: true
machine:
  type: worker
...
```

First we need to define our cluster:

```hcl
proxmox_host     = "node1.example.com"

vpc_main_cidr = "172.16.0.0/24"

# We will create one control-plane node on the Proxmox node `node1` (count = 1)
controlplane = {
  "node1" = {
    id    = 500
    count = 1,
    cpu   = 2,
    mem   = 6144,
  },
  "node2" = {
    id    = 520
    count = 0,
    cpu   = 2,
    mem   = 6144,
  },
}

# One web and worker node:
instances = {
  "node1" = {
    web_id       = 1000
    web_count    = 1,
    web_cpu      = 2,
    web_mem      = 4096,
    worker_id    = 1050
    worker_count = 1,
    worker_cpu   = 2,
    worker_mem   = 4096,
  },
  "node2" = {
    web_id       = 2000
    web_count    = 0,
    web_cpu      = 2,
    web_mem      = 4096,
    worker_id    = 2050
    worker_count = 0,
    worker_cpu   = 2,
    worker_mem   = 4096,
  },
}
```

Create all configs

```shell
make init create-config create-templates
```

Launch the control-plane node

```shell
make create-cluster
# wait ~2 minutes
make bootstrap
```

Receive `kubeconfig` file

```shell
make kubeconfig
```

```shell
kubectl get nodes -o wide
kubectl get pods -o wide -A
```
