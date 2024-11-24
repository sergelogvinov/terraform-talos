# Proxmox

It was tested on Proxmox version 8.2

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
# Proxmox API host
proxmox_host = "node1.example.com"

# Local proxmox subnets
vpc_main_cidr = ["172.16.0.0/24", "fd60:172:16::/64"]

# Node configuration
nodes = {
  "node1" = {
    storage = "data",
    ip4 = "1.1.0.1"
    ip6 = "2001:1:2:1::/64",
    gw6 = "2001:1:2:1::64",
  },
  "node2" = {
    storage = "data",
    ip4 = "1.1.0.2"
    ip6 = "2001:1:2:2::/64",
    gw6 = "2001:1:2:2::64",
  },
}

# We will create one control-plane node on the Proxmox node `node1` (count = 1)
controlplane = {
  "node1" = {
    id    = 500,
    count = 1,
    cpu   = 2,
    mem   = 6144,
  },
  "node2" = {
    id    = 520,
    count = 0,
    cpu   = 2,
    mem   = 6144,
  },
}

# One web and worker node:
instances = {
  "node1" = {
    enabled      = true,
    web_id       = 1000,
    web_count    = 1,
    web_cpu      = 2,
    web_mem      = 4096,
    worker_id    = 1050,
    worker_count = 1,
    worker_cpu   = 2,
    worker_mem   = 4096,
  },
  "node2" = {
    enabled      = true,
    web_id       = 2000,
    web_count    = 0,
    web_cpu      = 2,
    web_mem      = 4096,
    worker_id    = 2050,
    worker_count = 0,
    worker_cpu   = 2,
    worker_mem   = 4096,
  },
}
```

Create the age key (optional)
This key will be used to encrypt the secrets, check the .sops.yaml file.

```shell
make create-age
export SOPS_AGE_KEY_FILE=age.key.txt
```

Create all configs

```shell
make init create-config create-templates
```

Launch the control-plane node

```shell
make create-cluster
# wait ~30 seconds, full cli command will be showns on terraform output
talosctl apply-config --insecure --nodes ${IP} --config-patch @_cfgs/controlplane-01a.yaml --file _cfgs/controlplane.yaml
# wait ~10 seconds
make bootstrap
```

Receive `kubeconfig` file

```shell
make kubeconfig
```

```shell
make system system-base
```

Test the cluster

```shell
export KUBECONFIG=kubeconfig

kubectl get nodes -o wide
kubectl get pods -o wide -A
kubectl get csistoragecapacities -ocustom-columns=CLASS:.storageClassName,AVAIL:.capacity,ZONE:.nodeTopology.matchLabels -A
```

Resault:

```shell
# make nodes
NAME               STATUS   ROLES           AGE     VERSION   INTERNAL-IP    EXTERNAL-IP                 OS-IMAGE         KERNEL-VERSION   CONTAINER-RUNTIME         REGION     ZONE    INSTANCE-TYPE
controlplane-01a   Ready    control-plane   113m    v1.31.2   172.16.0.142   2a01:xxx:xxx:3064:1::2d02   Talos (v1.8.2)   6.6.58-talos     containerd://2.0.0-rc.6   region-1   rnd-1   4VCPU-6GB
web-01a            Ready    web             110m    v1.31.2   172.16.0.129   2a01:xxx:xxx:3064:2::2c0c   Talos (v1.8.2)   6.6.58-talos     containerd://2.0.0-rc.6   region-1   rnd-1   2VCPU-2GB
web-01b            Ready    web             4m54s   v1.31.2   172.16.0.130   2a01:xxx:xxx:3064:2::2c0d   Talos (v1.8.2)   6.6.58-talos     containerd://2.0.0-rc.6   region-1   rnd-1   2VCPU-2GB
web-02a            Ready    web             4m54s   v1.31.2   172.16.0.145   2a01:xxx:xxx:30ac:3::2ff4   Talos (v1.8.2)   6.6.58-talos     containerd://2.0.0-rc.6   region-1   rnd-2   2VCPU-2GB
web-02b            Ready    web             4m54s   v1.31.2   172.16.0.146   2a01:xxx:xxx:30ac:3::2ff5   Talos (v1.8.2)   6.6.58-talos     containerd://2.0.0-rc.6   region-1   rnd-2   2VCPU-2GB
worker-01a         Ready    worker          4m54s   v1.31.2   172.16.0.135   2a01:xxx:xxx:3064:2::2c96   Talos (v1.8.2)   6.6.58-talos     containerd://2.0.0-rc.6   region-1   rnd-1   2VCPU-2GB
worker-02a         Ready    worker          32s     v1.31.2   172.16.0.151   2a01:xxx:xxx:30ac:3::307e   Talos (v1.8.2)   6.6.58-talos     containerd://2.0.0-rc.6   region-1   rnd-2   2VCPU-2GB
```
