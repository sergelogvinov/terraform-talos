# Terraform examples for Talos

I store here the terraform code to launch Talos in the clouds.
I wouldn't use the terrafrom modules from internet.
The goal is to create all cloud services from scratch.

* [Azure](azure) - many regions, many zones.
Well tested with talos 1.1.x.
Platform addons: CCM,CSI,Autoscaler
* [GCP](gcp-zonal) - one region, many zones.
Well tested with talos 0.14.0.
Platform addons: CCM,CSI,Autoscaler
* [Hetzner](hetzner) - many regions.
Well tested with talos 0.14.0.
Platform addons: CCM,CSI,Autoscaler
* [Openstack](openstack) - many regions, many zones.
Well tested with talos 1.1.x.
Platform addons: CCM,CSI
* [Oracle](oracle) - many regions, many zones.
Well tested with talos 1.0.0.
* [Scaleway](scaleway) - many regions.
Well tested with talos 1.0.0.
Platform addons: CCM

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
