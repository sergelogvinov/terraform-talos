
CLUSTERNAME := "talos-k8s-azure"
CPFIRST := ${shell terraform output -raw controlplane_endpoint 2>/dev/null}
ENDPOINT ?= $(shell terraform output -no-color -raw controlplane_endpoint_public 2>/dev/null)
ifneq (,$(findstring Warning,${ENDPOINT}))
ENDPOINT := api.cluster.local
else ifeq (,$(ENDPOINT))
ENDPOINT := api.cluster.local
endif

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean:
	rm -rf _cfgs/ terraform.tfvars.json
	rm -f kubeconfig talosctl
	rm -rf .terraform.lock.hcl .terraform/ terraform.tfstate terraform.tfstate.backup

create-config: ## Genereate talos configs
	talosctl gen config --output-dir _cfgs --with-docs=false --with-examples=false ${CLUSTERNAME} https://${ENDPOINT}:6443
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${ENDPOINT}

create-templates:
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

create-deployments:
	helm template --namespace=kube-system -f deployments/azure-ccm.yaml azure-cloud-controller-manager \
		cloud-provider-azure > deployments/azure-cloud-controller-manager.yaml

	helm template --namespace=kube-system -f deployments/azure-autoscaler.yaml cluster-autoscaler-azure \
		autoscaler/cluster-autoscaler > deployments/azure-autoscaler-result.yaml

	helm template --namespace=kube-system -f deployments/azuredisk-csi-driver.yaml azuredisk-csi-driver \
		azuredisk-csi-driver/azuredisk-csi-driver > deployments/azuredisk-csi-driver-result.yaml

create-network: ## Create networks
	cd prepare && terraform init && terraform apply -auto-approve

create-controlplane-bootstrap:
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${ENDPOINT}
	talosctl --talosconfig _cfgs/talosconfig --nodes ${CPFIRST} bootstrap

create-controlplane: ## Bootstrap controlplane
	terraform apply -target=azurerm_linux_virtual_machine.controlplane

create-kubeconfig: ## Download kubeconfig
	talosctl --talosconfig _cfgs/talosconfig --nodes ${CPFIRST} kubeconfig .
	kubectl --kubeconfig=kubeconfig config set clusters.talos-k8s-azure.server https://${ENDPOINT}:6443
	kubectl --kubeconfig=kubeconfig config set-context --current --namespace=kube-system

create-infrastructure: ## Bootstrap all nodes
	terraform apply
