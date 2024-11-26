
CLUSTERNAME:="talos-k8s-proxmox"
CPFIRST := ${shell terraform output -raw controlplane_firstnode 2>/dev/null}
ENDPOINT := ${shell terraform output -raw controlplane_endpoint 2>/dev/null}
ifneq (,$(findstring Warning,${ENDPOINT}))
ENDPOINT := api.cluster.local
endif

SOPS_AGE_KEY_FILE ?= age.key.txt

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: init
init: ## Initialize terraform
	terraform init -upgrade

create-age: ## Create age key
	age-keygen -o age.key.txt

create-config: ## Generete talos configs
	terraform apply -auto-approve -target=local_file.worker_patch
	talosctl gen config --output-dir _cfgs --with-docs=false --with-examples=false ${CLUSTERNAME} https://${ENDPOINT}:6443
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${ENDPOINT}

create-templates:
	@echo 'podSubnets: "10.32.0.0/12,fd00:10:32::/64"'         >  _cfgs/tfstate.vars
	@echo 'serviceSubnets: "10.200.0.0/22,fd40:10:200::/108"'  >> _cfgs/tfstate.vars
	@echo 'apiDomain: api.cluster.local'                       >> _cfgs/tfstate.vars
	@yq eval '.cluster.network.dnsDomain' _cfgs/controlplane.yaml | awk '{ print "domain: "$$1}'       >> _cfgs/tfstate.vars
	@yq eval '.cluster.clusterName' _cfgs/controlplane.yaml       | awk '{ print "clusterName: "$$1}'  >> _cfgs/tfstate.vars
	@yq eval '.cluster.id' _cfgs/controlplane.yaml                | awk '{ print "clusterID: "$$1}'    >> _cfgs/tfstate.vars
	@yq eval '.cluster.secret' _cfgs/controlplane.yaml            | awk '{ print "clusterSecret: "$$1}'>> _cfgs/tfstate.vars
	@yq eval '.machine.token'  _cfgs/controlplane.yaml            | awk '{ print "tokenMachine: "$$1}' >> _cfgs/tfstate.vars
	@yq eval '.machine.ca.crt' _cfgs/controlplane.yaml            | awk '{ print "caMachine: "$$1}'    >> _cfgs/tfstate.vars
	@yq eval '.cluster.token'  _cfgs/controlplane.yaml            | awk '{ print "token: "$$1}'        >> _cfgs/tfstate.vars
	@yq eval '.cluster.ca.crt' _cfgs/controlplane.yaml            | awk '{ print "ca: "$$1}'           >> _cfgs/tfstate.vars

	@yq eval -o=json '{"kubernetes": .}' _cfgs/tfstate.vars > terraform.tfvars.sops.json
	@sops --encrypt -i terraform.tfvars.sops.json
	@yq eval .ca _cfgs/tfstate.vars | base64 --decode > _cfgs/ca.crt
	@sops --encrypt --input-type=yaml --output-type=yaml _cfgs/talosconfig > _cfgs/talosconfig.sops.yaml
	@sops --encrypt --input-type=yaml --output-type=yaml _cfgs/controlplane.yaml > _cfgs/controlplane.sops.yaml
	@git add -f _cfgs/talosconfig.sops.yaml _cfgs/ca.crt terraform.tfvars.sops.json

create-cluster: ## Create cluster
	terraform apply

bootstrap: ## Bootstrap controlplane
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${ENDPOINT}
	talosctl --talosconfig _cfgs/talosconfig --nodes ${CPFIRST} bootstrap

.PHONY: kubeconfig
kubeconfig: ## Download kubeconfig
	rm -f kubeconfig
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${ENDPOINT}
	talosctl --talosconfig _cfgs/talosconfig --nodes ${CPFIRST} kubeconfig .
	kubectl --kubeconfig=kubeconfig config set clusters.${CLUSTERNAME}.server https://[${ENDPOINT}]:6443
	kubectl --kubeconfig=kubeconfig config set-context --current --namespace=kube-system

##########################################################################################

nodes: ## Show kubernetes nodes
	@kubectl get nodes -owide --sort-by '{.metadata.name}' --label-columns topology.kubernetes.io/region,topology.kubernetes.io/zone,node.kubernetes.io/instance-type

system:
	helm --kubeconfig=kubeconfig upgrade -i --namespace=kube-system --version=1.16.4 -f deployments/cilium.yaml \
		cilium cilium/cilium

	kubectl --kubeconfig=kubeconfig apply -f ../_deployments/vars/coredns-local.yaml

	helm --kubeconfig=kubeconfig upgrade -i --namespace=kube-system -f deployments/talos-ccm.yaml \
		talos-cloud-controller-manager \
		oci://ghcr.io/siderolabs/charts/talos-cloud-controller-manager

system-flux:
	kubectl --kubeconfig=kubeconfig apply -f ../_deployments/vars/flux-result.yaml

system-base:
	helm --kubeconfig=kubeconfig upgrade -i --namespace=kube-system -f ../_deployments/vars/metrics-server.yaml \
		metrics-server metrics-server/metrics-server

	helm --kubeconfig=kubeconfig upgrade -i --namespace=kube-system -f vars/proxmox-ccm.yaml \
		proxmox-cloud-controller-manager oci://ghcr.io/sergelogvinov/charts/proxmox-cloud-controller-manager

	#
	# File vars/secrets.proxmox.yaml was created by terraform
	#
	kubectl --kubeconfig=kubeconfig apply -f vars/proxmox-ns.yaml
	helm --kubeconfig=kubeconfig secrets upgrade -i --namespace=csi-proxmox -f vars/proxmox-csi.yaml -f vars/secrets.proxmox.yaml \
		proxmox-csi-plugin oci://ghcr.io/sergelogvinov/charts/proxmox-csi-plugin
