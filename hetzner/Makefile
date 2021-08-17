
prepare-image:
	ssh-keygen -f /.ssh/terraform -N '' -t rsa

	cd prepare
	terraform init
	terraform apply -auto-approve

create-lb:
	terraform init
	terraform apply -auto-approve -target=hcloud_load_balancer.api

create-config:
	talosctl gen config --output-dir _cfgs --with-docs=false --with-examples=false talos-k8s-hezner https://127.0.0.1:6443

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

create-controlplane:
	terraform apply -target=null_resource.controlplane

create-infrastructure:
	cd modules/worker && terraform init
	terraform apply
