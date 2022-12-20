
ENDPOINT:=${shell terraform output -raw controlplane_endpoint 2>/dev/null}
ifeq ($(ENDPOINT),)
ENDPOINT := 127.0.0.1
endif

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

create-lb: ## Create load balancer
	terraform init
	terraform apply -auto-approve -target=output.controlplane_endpoint
	terraform refresh

create-config: ## Genereate talos configs
	talosctl gen config --output-dir _cfgs --with-docs=false --with-examples=false talos-k8s-scaleway https://${ENDPOINT}:6443
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
	talosctl --talosconfig _cfgs/talosconfig --nodes 172.16.0.11 bootstrap

create-controlplane: ## Bootstrap first controlplane node
	terraform refresh
	terraform apply -target=scaleway_instance_server.controlplane -target=scaleway_vpc_public_gateway_dhcp_reservation.controlplane

	sleep 30
	@$(MAKE) create-controlplane-bootstrap

create-infrastructure: ## Bootstrap all nodes
	terraform apply

create-kubeconfig: ## Prepare kubeconfig
	talosctl --talosconfig _cfgs/talosconfig --nodes 172.16.0.11 kubeconfig .
	kubectl --kubeconfig=kubeconfig config set clusters.talos-k8s-scaleway.server https://${ENDPOINT}:6443
	kubectl --kubeconfig=kubeconfig config set-context --current --namespace=kube-system

create-deployments:
	helm template --namespace=kube-system   --version=1.12.4 -f deployments/cilium.yaml cilium \
		cilium/cilium > deployments/cilium-result.yaml
	helm template --namespace=ingress-nginx --version=4.4.0 -f deployments/ingress.yaml ingress-nginx \
		ingress-nginx/ingress-nginx > deployments/ingress-result.yaml

deploy-csi:
	dd if=/dev/urandom bs=1 count=16 2>/dev/null | hexdump -e '"%00x"' > scw-csi-secret.secret
	kubectl --kubeconfig=kubeconfig create secret generic scw-csi-secret --from-file=encryptionPassphrase=scw-csi-secret.secret

	kubectl --kubeconfig=kubeconfig apply -f deployments/scaleway-csi.yaml
	kubectl --kubeconfig=kubeconfig apply -f deployments/scaleway-csi-node.yaml
	kubectl --kubeconfig=kubeconfig apply -f deployments/scaleway-storage.yaml
	rm -f scw-csi-secret.secret
