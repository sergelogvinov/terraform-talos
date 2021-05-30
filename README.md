# terraform-talos

Terraform examples to run Talos

* terraform
* talosctl
* kubectl
* yq

## Talos on Hetzner Cloud

```bash
cd hetzner

# create the cluster configuration
talosctl gen config --output-dir _cfgs --with-docs=false --with-examples=false talos-k8s-hezner https://127.0.0.1:6443
yq ea -P '. as $item ireduce ({}; . * $item )' _cfgs/controlplane.yaml templates/controlplane.yaml.tpl > templates/controlplane.yaml
```

```bash
kubectl -n kube-system create secret generic hcloud --from-literal=network= --from-literal=token=
```
