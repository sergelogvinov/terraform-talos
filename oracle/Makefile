
ENDPOINT:=${shell terraform output -raw controlplane_endpoint 2>/dev/null}

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

create-network: ## Create networks
	cd prepare && terraform init && terraform apply -target=oci_core_vcn.main -auto-approve
	cd prepare && terraform apply -auto-approve

create-lb: ## Create loadbalancer
	terraform init
	terraform apply -auto-approve -target=output.controlplane_endpoint -target=oci_network_load_balancer_network_load_balancer.contolplane
	terraform apply -auto-approve -target=oci_network_load_balancer_network_load_balancer.web

create-config: ## Genereate talos configs
	talosctl gen config --output-dir _cfgs --with-docs=false --with-examples=false talos-k8s-oracle https://${ENDPOINT}:6443
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${ENDPOINT}

create-templates:
	@yq ea -P '. as $$item ireduce ({}; . * $$item )' _cfgs/controlplane.yaml templates/controlplane.yaml.tpl > templates/controlplane.yaml
	@echo 'podSubnets: "10.32.0.0/12,fd00:10:32::/102"'        >  _cfgs/tfstate.vars
	@echo 'serviceSubnets: "10.200.0.0/22,fd40:10:200::/112"'  >> _cfgs/tfstate.vars
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

create-controlplane: ## Bootstrap controlplane node
	terraform apply -auto-approve -target=oci_core_instance.controlplane

create-kubeconfig:
	talosctl --talosconfig _cfgs/talosconfig --nodes 172.16.1.11 kubeconfig .

create-deployments:
	helm template --namespace=kube-system   --version=1.11.0 -f deployments/cilium.yaml cilium \
		cilium/cilium > deployments/cilium_result.yaml
	helm template --namespace=ingress-nginx --version=4.0.16 -f deployments/ingress.yaml ingress-nginx \
		ingress-nginx/ingress-nginx > deployments/ingress_result.yaml
