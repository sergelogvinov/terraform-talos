
ENDPOINT:=${shell terraform output -raw controlplane_endpoint_public 2>/dev/null}
ifeq ($(ENDPOINT),)
ENDPOINT := 127.0.0.1
endif

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

create-lb: ## Create load balancer
	terraform init
	terraform apply -target=output.controlplane_endpoint_public --refresh -auto-approve
	terraform refresh

create-config: ## Genereate talos configs
	talosctl gen config --output-dir _cfgs --with-docs=false --with-examples=false talos-k8s-openstack https://${ENDPOINT}:6443
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${ENDPOINT}

create-templates:
	@yq ea -P '. as $$item ireduce ({}; . * $$item )' _cfgs/controlplane.yaml templates/controlplane.yaml.tpl > templates/controlplane.yaml
	@echo 'podSubnets: "10.32.0.0/12,fd00:10:32::/102"'        >  _cfgs/tfstate.vars
	@echo 'serviceSubnets: "10.200.0.0/22,fd40:10:200::/112"'  >> _cfgs/tfstate.vars
	@echo 'nodeSubnets: "172.16.0.0/12"'                       >> _cfgs/tfstate.vars
	@echo 'apiDomain: api.cluster.local'                       >> _cfgs/tfstate.vars
	@yq eval '.cluster.network.dnsDomain' _cfgs/controlplane.yaml | awk '{ print "domain: "$$1}'       >> _cfgs/tfstate.vars
	@yq eval '.cluster.clusterName' _cfgs/controlplane.yaml       | awk '{ print "clusterName: "$$1}'  >> _cfgs/tfstate.vars
	@yq eval '.cluster.id' _cfgs/controlplane.yaml                | awk '{ print "clusterID: "$$1}'    >> _cfgs/tfstate.vars
	@yq eval '.cluster.secret' _cfgs/controlplane.yaml            | awk '{ print "clusterSecret: "$$1}'>> _cfgs/tfstate.vars
	@yq eval '.machine.token'  _cfgs/controlplane.yaml            | awk '{ print "tokenMachine: "$$1}' >> _cfgs/tfstate.vars
	@yq eval '.machine.ca.crt' _cfgs/controlplane.yaml            | awk '{ print "caMachine: "$$1}'    >> _cfgs/tfstate.vars
	@yq eval '.cluster.token'  _cfgs/controlplane.yaml            | awk '{ print "token: "$$1}'        >> _cfgs/tfstate.vars
	@yq eval '.cluster.ca.crt' _cfgs/controlplane.yaml            | awk '{ print "ca: "$$1}'           >> _cfgs/tfstate.vars

	@yq eval -o=json '{"kubernetes": .}' _cfgs/tfstate.vars > terraform.tfvars.json

create-controlplane-bootstrap:
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${ENDPOINT}
	talosctl --talosconfig _cfgs/talosconfig --nodes ${ENDPOINT} bootstrap

create-deployments:
	helm template --namespace=kube-system   --version=1.12.7 -f deployments/cilium.yaml cilium \
		cilium/cilium > deployments/cilium-result.yaml
	helm template --namespace=ingress-nginx --version=4.4.0 -f deployments/ingress.yaml ingress-nginx \
		ingress-nginx/ingress-nginx > deployments/ingress-result.yaml

create-network: ## Create networks
	cd prepare && terraform init && terraform apply -auto-approve

create-controlplane: ## Bootstrap controlplane
	terraform apply -target=module.controlplane
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${ENDPOINT}
	talosctl --talosconfig _cfgs/talosconfig --nodes ${ENDPOINT} bootstrap

create-kubeconfig: ## Download kubeconfig
	talosctl --talosconfig _cfgs/talosconfig --nodes ${ENDPOINT} kubeconfig .
	kubectl --kubeconfig=kubeconfig config set clusters.talos-k8s-openstack.server https://${ENDPOINT}:6443
	kubectl --kubeconfig=kubeconfig config set-context --current --namespace=kube-system

create-infrastructure: ## Bootstrap all nodes
	terraform apply
