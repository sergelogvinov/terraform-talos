# Terraform examples to launch Talos.

I store here the terraform code to launch Talos in the clouds.
I wouldn't use the terrafrom modules from internet.
The goal is to create all cloud services from scratch.

## Ideas

First, I will create separate clusters on each cloud provider, test them thoroughly, and bring them close to production readiness. When I merge these separate Kubernetes clusters into one, they will have a single control plane.

Why is it so important?

Having a single Kubernetes control plane that spans multiple cloud providers can offer several benefits:

* Improved resilience and availability: By using multiple cloud providers, you can reduce the risk of downtime due to a single point of failure.
* Flexibility: A single control plane allows you to easily move workloads between different cloud providers, depending on your needs.
* Cost savings: You can take advantage of the different pricing models and discounts offered by different cloud providers to save on costs.
* Improved security: By using multiple cloud providers, you can implement a defense-in-depth strategy to protect your data and reduce the risk of a security breach.
* Decrease the time to recovery (TTR)

## Clouds

| Platform | Checked Talos version | Addons | Setup type | Nat |
|---|---|---|---|---|
| [Azure](azure)         | 1.3.0  | CCM,CSI,Autoscaler | many regions, many zones | &check; |
| [Exoscale](exoscale)   | 1.3.0  | CCM,Autoscaler     | many regions | &cross; |
| [GCP](gcp-zonal)       | 1.3.0  | CCM,CSI,Autoscaler | one region, many zones | &check; |
| [Hetzner](hetzner)     | 1.3.0  | CCM,CSI,Autoscaler | many regions | &cross; |
| [Openstack](openstack) | 1.3.0  | CCM,CSI            | many regions, many zones | &check; |
| [Oracle](oracle)       | 1.3.0  | CCM,~~CSI~~,Autoscaler | one region, many zones | &check; |
| [Scaleway](scaleway)   | 1.3.0  | CCM,CSI            | one region | &check; |


## Common

* **cilium** network with vxlan tunnels.
* **ingress-nginx** (daemonsets) runs on ```web``` role nodes.
It uses ```hostNetwork``` ports 80,443 for optimizations.
It helps me to tweak the kernel on a host and apply it to ingress controller.
And I can disable conntrack too.
* **coredns-local** (daemonsets) uses dummy interface on al nodes and has ip ```169.254.2.53```
It decrease the dns response (all traffic does not leave the node).
It makes sense in multi-cloud setup. Kubernets still does not have geo-based load balancer capabilities (alfa).
* **rancher.io/local-path** as default storage class.
