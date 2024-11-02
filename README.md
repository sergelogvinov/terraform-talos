# Terraform examples to launch Talos.

This repository was created to store Terraform code for launching Talos in the clouds/bare-metal.
When I added features/cloud platform integrations to Talos, I needed to run tests manually.
To make things easier, I created this repository.

There are no GitOps best practices here - no FluxCD, ArgoCD, or other GitOps tools.
Each step is applied manually because I need to test everything to ensure it works as expected.

* I chose not to use Terraform modules from the internet; the goal here is to build all cloud services from scratch.
* I `don’t maintain backward compatibility` and always use the latest versions of Terraform and cloud provider tools.
* Kubernetes isn’t fully ready for multi-cloud environments, as many components were designed for single-environment setups. So did some changes to each cloud provider controllers to improve compatibility. (like CCM, CSI, etc.)
* The [Talos CCM](https://github.com/siderolabs/talos-cloud-controller-manager) project was created to make multi-cloud setups more cloud-native, addressing some common issues in multi-cloud environments.

Some examples are production ready, and I’ve been using them with minor adjustments to fit company’s needs.
In most cases in my production setup, I use two or more cloud providers within a single Kubernetes cluster.

Everything here is under the `MIT license`.
Feel free to clone, copy the code.
If this project helps you, please give it a `star`.
It helps me to understand how many people are interested in this project/ideas.
And it motivates me to keep working on it. Your support encourages me to add/sync new features.

## Ideas

First, I will create separate clusters on each cloud provider, test them thoroughly, and bring them close to production readiness.
When I merge these separate Kubernetes clusters into one, they will have a single control plane.

Why is it so important?

Having a single Kubernetes control plane that spans multiple cloud providers can offer several benefits:

* Improved resilience and availability: By using multiple cloud providers, you can reduce the risk of downtime due to cloud provider outages or other issues.
* Flexibility: A single control plane allows you to easily move workloads between different cloud providers, depending on your needs.
* Cost savings: You can take advantage of the different pricing models and discounts offered by different cloud providers to save on costs.
* Improved security: By using multiple cloud providers, you can implement a defense-in-depth strategy to protect your data and reduce the risk of a security breach.
* Decrease the time to recovery (TTR)

## Clouds

| Platform | Checked Talos version | Addons | Setup type | Nat-IPv4 | IPv6 | Pod with global IPv6 |
|---|---|---|---|---|---|---|
| [Azure](azure)         | 1.3.4  | CCM,CSI,Autoscaler | many regions, many zones | &check; | &check; | &cross; |
| [Exoscale](exoscale)   | 1.3.0  | CCM,Autoscaler     | many regions | &cross; | | |
| [GCP](gcp-zonal)       | 1.3.4  | CCM,CSI,Autoscaler | one region, many zones | &check; | &check; | &check; |
| [Hetzner](hetzner)     | 1.7.6  | CCM,CSI,Autoscaler | many regions, one network zone | &cross; | &check; | &check; |
| [Openstack](openstack) | 1.3.4  | CCM,CSI            | many regions, many zones | &check; | &check; | &check; |
| [Oracle](oracle)       | 1.3.4  | CCM,CSI,Autoscaler | one region, many zones | &check; | &check; | |
| [Proxmox](proxmox)     | 1.8.2  | CCM,CSI            | one region, mny zones | &check; | &check; | &check; |
| [Scaleway](scaleway)   | 1.7.6  | CCM,CSI            | one region | &check; | &check; | &check; |

## Known issues

* Talos does not support upstream Oracle CSI, use my [fork](https://github.com/sergelogvinov/oci-cloud-controller-manager)

## Multi cloud compatibility

CCM controllers have different modes:
* Talos CCM in mode: `cloud-node`
* Other CCMs in mode: `cloud-node-lifecycle`

CCM compatibility has been tested in multi-cloud setups, and in most cases, they work well together.

|   | Azure | GCP | Hetzner | Openstack | Proxmox |
|---|---|---|---|---|---|
| Azure     | | &check; | &check; | &check; | &check; |
| Exoscale  | |         |         |         |
| GCP       | &check; | | &check; | &check; | &check; |
| Hetzner   | &check; | &check; | | &check; | &check; |
| Openstack | &check; | &check; | &check; | | &check; |
| Proxmox   | &check; | &check; | &check; | &check; | |

## Common

* **cilium** network with vxlan tunnels.
* **ingress-nginx** (daemonsets) runs on ```web``` role nodes.
It uses ```hostNetwork``` ports 80,443 for optimizations.
It helps me to tweak the kernel on a host and apply it to ingress controller.
And I can disable conntrack too.
* **coredns-local** (daemonsets) uses dummy interface on al nodes and has ip ```169.254.2.53```
It decrease the dns response (all traffic does not leave the node).
* **rancher.io/local-path** as default storage class.

The common deployoment you can find in [_deployments](/_deployments/) folder.

## References

* [Talos](https://www.talos.dev/)
* [Talos CCM](https://github.com/siderolabs/talos-cloud-controller-manager)
