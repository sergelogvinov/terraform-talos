# Talos on Azure Cloud

## Create IAM roles

### Create roles

Terraform will create the roles.
```az ad sp``` creates the accounts and assign the roles.
Do not forget to save account credits.

```shell
cd init
terraform init
terraform apply

az ad sp create-for-rbac --name "kubernetes-csi" --role kubernetes-csi --scopes="/subscriptions/<subscription-id>" --output json
az ad sp create-for-rbac --name "kubernetes-node-autoscaler" --role kubernetes-node-autoscaler --scopes="/subscriptions/<subscription-id>" --output json

# add aadClientId,aadClientSecret to the file _cfgs/azure.json, andd apply it
kubectl -n kube-system create secret generic azure-cluster-autoscaler --from-file=azure.json=_cfgs/azure.json
kubectl -n kube-system create secret generic azure-csi --from-file=azure.json=_cfgs/azure.json
```

## Local utilities

* terraform
* talosctl
* kubectl
* yq

# Network diagram


## Kubernetes addons

* [Azure CCM](https://github.com/kubernetes-sigs/cloud-provider-azure)
* [Azure CSI](https://github.com/kubernetes-sigs/azuredisk-csi-driver)
* [Azure Node AutoScaler](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/azure/README.md)
* [cilium](https://github.com/cilium/cilium) 1.12.5
* [metrics-server](https://github.com/kubernetes-sigs/metrics-server) 0.5.0
* [rancher.io/local-path](https://github.com/rancher/local-path-provisioner) 0.0.19
* [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) 4.4.2

# Known Issues

* CSI controller needs a region name. And I think this can affect multi region setup. The half solution is using the node identity method, and receiving the region name from the meta server.
