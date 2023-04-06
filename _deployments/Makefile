
help:
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

helm-repos: ## add helm repos
	helm repo add cilium               https://helm-charts.sinextra.dev
	helm repo add metrics-server       https://kubernetes-sigs.github.io/metrics-server/
	helm repo add ingress-nginx        https://kubernetes.github.io/ingress-nginx
	helm repo update

create-deployments: ## create templates
	helm template --namespace=kube-system  --version=1.12.7 -f vars/cilium.yaml cilium \
		cilium/cilium > vars/cilium-result.yaml

	helm template --namespace=kube-system -f vars/metrics-server.yaml metrics-server \
		metrics-server/metrics-server > vars/metrics-server-result.yaml

	# helm template --namespace=local-path-storage -f vars/local-path-storage.yaml local-path-provisioner \
	# 	~/work/sergelogvinov/local-path-provisioner/deploy/chart/local-path-provisioner > vars/local-path-storage-result.yaml

	helm template --namespace=ingress-nginx --version=4.6.0 -f vars/ingress.yaml ingress-nginx \
		ingress-nginx/ingress-nginx > vars/ingress-result.yaml
