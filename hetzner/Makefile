
CLUSTERNAME := "talos-k8s-hetzner"
CPFIRST := ${shell terraform output -raw controlplane_firstnode 2>/dev/null}
ENDPOINT := ${shell terraform output -raw controlplane_endpoint 2>/dev/null}
ifneq (,$(findstring Warning,${ENDPOINT}))
ENDPOINT := api.cluster.local
endif

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean: ## Clean all
	terraform destroy -auto-approve
	rm -rf _cfgs
	rm -f kubeconfig terraform.tfvars.json

prepare:
	@[ -f ~/.ssh/terraform ] || ssh-keygen -f ~/.ssh/terraform -N '' -t rsa

create-lb: ## Create load balancer
	terraform init
	terraform apply -auto-approve -target=hcloud_floating_ip.api -target=hcloud_load_balancer.api
	terraform refresh

create-config: ## Genereate talos configs
	talosctl gen config --output-dir _cfgs --with-docs=false --with-examples=false ${CLUSTERNAME} https://${ENDPOINT}:6443
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${ENDPOINT}

create-templates:
	@echo 'podSubnets: "10.32.0.0/12,fd40:10:32::/102"'        >  _cfgs/tfstate.vars
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

create-controlplane-bootstrap:
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${CPFIRST}
	talosctl --talosconfig _cfgs/talosconfig --nodes ${CPFIRST} bootstrap

create-controlplane: ## Bootstrap first controlplane node
	terraform apply -auto-approve -target=hcloud_server.controlplane -target=null_resource.controlplane

create-infrastructure: ## Bootstrap all nodes
	terraform apply

create-kubeconfig: ## Prepare kubeconfig
	talosctl --talosconfig _cfgs/talosconfig --nodes ${CPFIRST} kubeconfig .
	kubectl --kubeconfig=kubeconfig config set clusters.${CLUSTERNAME}.server https://${ENDPOINT}:6443
	kubectl --kubeconfig=kubeconfig config set-context --current --namespace=kube-system

create-secrets:
	dd if=/dev/urandom bs=1 count=16 2>/dev/null | hexdump -e '"%00x"' > hcloud-csi-secret.secret
	kubectl --kubeconfig=kubeconfig create secret generic hcloud-csi-secret --from-file=encryptionPassphrase=hcloud-csi-secret.secret
	rm -f hcloud-csi-secret.secret

helm-repos: ## add helm repos
	helm repo add hcloud               https://charts.hetzner.cloud
	helm repo update

create-deployments:
	helm template --namespace=kube-system -f deployments/hcloud-cloud-controller-manager.yaml \
		hcloud-cloud-controller-manager hcloud/hcloud-cloud-controller-manager > deployments/hcloud-cloud-controller-manager-result.yaml
