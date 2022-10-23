
ENDPOINT:=${shell terraform output -raw controlplane_endpoint 2>/dev/null}
ifeq ($(ENDPOINT),)
ENDPOINT := 127.0.0.1
endif

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

create-controlplane: ## Bootstrap first controlplane node
	terraform refresh
	terraform apply -target=exoscale_instance_pool.controlplane

create-infrastructure: ## Bootstrap all nodes
	terraform apply

create-kubeconfig: ## Prepare kubeconfig
	talosctl --talosconfig _cfgs/talosconfig --nodes ${ENDPOINT} kubeconfig .
	kubectl --kubeconfig=kubeconfig config set clusters.talos-k8s-exoscale.server https://${ENDPOINT}:6443
	kubectl --kubeconfig=kubeconfig config set-context --current --namespace=kube-system

create-deployments:
	helm template --namespace=kube-system   --version=1.12.3 -f deployments/cilium.yaml cilium \
		cilium/cilium > deployments/cilium-result.yaml
	helm template --namespace=ingress-nginx --version=4.3.0  -f deployments/ingress.yaml ingress-nginx \
		ingress-nginx/ingress-nginx > deployments/ingress-result.yaml
