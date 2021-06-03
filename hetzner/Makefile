
prepare-image:
	ssh-keygen -f /.ssh/terraform -N '' -t rsa

	cd prepare
	terraform init
	terraform apply -auto-approve

create-config:
	talosctl gen config --output-dir _cfgs --with-docs=false --with-examples=false talos-k8s-hezner https://127.0.0.1:6443

create-templates:
	@yq ea -P '. as $$item ireduce ({}; . * $$item )' _cfgs/controlplane.yaml templates/controlplane.yaml.tpl > templates/controlplane.yaml
	@echo 'podSubnets: "10.32.0.0/12"'       >  _cfgs/tfstate.vars
	@echo 'serviceSubnets: "10.200.0.0/22"'  >> _cfgs/tfstate.vars
	@yq eval '.cluster.network.dnsDomain' _cfgs/init.yaml | awk '{ print "domain: "$$1}'       >> _cfgs/tfstate.vars
	@yq eval '.cluster.clusterName' _cfgs/init.yaml       | awk '{ print "cluster_name: "$$1}' >> _cfgs/tfstate.vars
	@yq eval '.machine.token'  _cfgs/init.yaml            | awk '{ print "tokenmachine: "$$1}' >> _cfgs/tfstate.vars
	@yq eval '.cluster.token'  _cfgs/init.yaml            | awk '{ print "token: "$$1}'        >> _cfgs/tfstate.vars
	@yq eval '.cluster.ca.crt' _cfgs/init.yaml            | awk '{ print "ca: "$$1}'           >> _cfgs/tfstate.vars

	@yq eval -j '{"kubernetes": .}' _cfgs/tfstate.vars > terraform.tfvars.json

create-controlplane:
	cd modules/worker && terraform init
	terraform init
	terraform apply -target=null_resource.controlplane_apply

create-infrastructure:
	terraform apply
