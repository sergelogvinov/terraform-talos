
ENDPOINT:=${shell terraform output -raw controlplane_endpoint 2>/dev/null}

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

prepare:
	@[ -f ~/.ssh/terraform ] || ssh-keygen -f ~/.ssh/terraform -N '' -t rsa

create-lb: ## Create load balancer
	terraform init
	terraform apply -auto-approve -target=output.controlplane_endpoint
	terraform output controlplane_endpoint

create-config: ## Genereate talos configs
	./talosctl gen config --output-dir _cfgs --with-docs=false --with-examples=false talos-k8s-hezner https://${ENDPOINT}:6443

create-templates:
	@yq ea -P '. as $$item ireduce ({}; . * $$item )' _cfgs/controlplane.yaml templates/controlplane.yaml.tpl > templates/controlplane.yaml
	@echo 'podSubnets: "10.32.0.0/12,fd00:10:32::/102"'        >  _cfgs/tfstate.vars
	@echo 'serviceSubnets: "10.200.0.0/22,fd40:10:200::/112"'  >> _cfgs/tfstate.vars
	@yq eval '.cluster.network.dnsDomain' _cfgs/controlplane.yaml | awk '{ print "domain: "$$1}'       >> _cfgs/tfstate.vars
	@yq eval '.cluster.clusterName' _cfgs/controlplane.yaml       | awk '{ print "cluster_name: "$$1}' >> _cfgs/tfstate.vars
	@yq eval '.machine.token'  _cfgs/controlplane.yaml            | awk '{ print "tokenmachine: "$$1}' >> _cfgs/tfstate.vars
	@yq eval '.cluster.token'  _cfgs/controlplane.yaml            | awk '{ print "token: "$$1}'        >> _cfgs/tfstate.vars
	@yq eval '.cluster.ca.crt' _cfgs/controlplane.yaml            | awk '{ print "ca: "$$1}'           >> _cfgs/tfstate.vars

	@yq eval -j '{"kubernetes": .}' _cfgs/tfstate.vars > terraform.tfvars.json

create-controlplane: ## Bootstrap first controlplane node
	terraform apply -target=hcloud_server.controlplane

create-infrastructure: ## Bootstrap all nodes
	cd modules/worker && terraform init
	terraform apply

create-kubeconfig:
	talosctl --talosconfig _cfgs/talosconfig --nodes 172.16.0.11 kubeconfig
