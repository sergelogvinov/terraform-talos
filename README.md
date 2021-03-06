# Terraform examples for Talos

I store here the terraform code to launch Talos in the clouds.
I wouldn't use the terrafrom modules from internet.
The goal is to create all cloud services from scratch.


| Platform | Checked Talos version | Addons | Setup type | Nat |
|---|---|---|---|---|
| [Azure](azure)         | 1.1.0  | CCM,CSI,Autoscaler | many regions, many zones | &check; |
| [GCP](gcp-zonal)       | 0.14.0 | CCM,CSI,Autoscaler | one region, many zones | &check; |
| [Hetzner](hetzner)     | 1.1.0  | CCM,CSI,Autoscaler | many regions | &cross; |
| [Openstack](openstack) | 1.1.0  | CCM,CSI            | many regions, many zones | &check; |
| [Oracle](oracle)       | 1.0.0  |                    | many regions, many zones | &check; |
| [Scaleway](scaleway)   | 1.1.0  | CCM,CSI            | one region | &check; |


## Common

* **cilium** network with vxlan tunnels.
* **ingress-nginx** (daemonsets) runs on ```web``` role nodes.
It uses ```hostNetwork``` ports 80,443 for optimizations.
It helps me to tweak the kernel on a host and apply it to ingress controller.
And I can disable conntrack too.
* **coredns-local** (daemonsets) uses dummy interface on al nodes and has ip ```169.254.2.53```
It increases the dns response (all traffic does not leave the node).
It makes sense in multi-cloud setup. Kubernets still does not have geo-based load balancer capabilities (alfa).
* **rancher.io/local-path** as default storage class.
