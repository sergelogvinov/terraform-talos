
CLUSTERNAME := "talos-k8s-scaleway"
ENDPOINT := ${shell terraform output -raw controlplane_endpoint 2>/dev/null}
ifeq ($(ENDPOINT),)
ENDPOINT := 127.0.0.1
else ifneq (,$(findstring Warning,${ENDPOINT}))
ENDPOINT := 127.0.0.1
endif

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean:
	rm -rf .terraform.lock.hcl .terraform/ terraform.tfstate terraform.tfstate.backup
	rm -f kubeconfig terraform.tfvars.sops.json

create-config: ## Genereate talos configs
	talosctl gen config --output-dir _cfgs --with-docs=false --with-examples=false ${CLUSTERNAME} https://${ENDPOINT}:6443
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${ENDPOINT}

create-templates:
	@echo 'podSubnets: "10.80.0.0/12,fd40:10:80::/96"'         >  _cfgs/tfstate.vars
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

	@yq eval -o=json '{"kubernetes": .}' _cfgs/tfstate.vars > terraform.tfvars.sops.json
	@sops --encrypt -i terraform.tfvars.sops.json
	@yq eval .ca _cfgs/tfstate.vars | base64 --decode > _cfgs/ca.crt
	@sops --encrypt --input-type=yaml --output-type=yaml _cfgs/talosconfig       > _cfgs/talosconfig.sops.yaml
	@sops --encrypt --input-type=yaml --output-type=yaml _cfgs/controlplane.yaml > _cfgs/controlplane.sops.yaml

create-lb: ## Create load balancer
	terraform init
	terraform apply -auto-approve -target=output.controlplane_endpoint
	terraform refresh

create-infrastructure: ## Bootstrap all nodes
	terraform apply

bootstrap: ## Bootstrap controlplane
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${ENDPOINT}
	talosctl --talosconfig _cfgs/talosconfig --nodes ${ENDPOINT} bootstrap

.PHONY: kubeconfig
kubeconfig: ## Download kubeconfig
	rm -f kubeconfig
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${ENDPOINT}
	talosctl --talosconfig _cfgs/talosconfig --nodes ${ENDPOINT} kubeconfig .
	kubectl --kubeconfig=kubeconfig config set clusters.${CLUSTERNAME}.server https://[${ENDPOINT}]:6443
	kubectl --kubeconfig=kubeconfig config set-context --current --namespace=kube-system

system-static:
	helm template --namespace=kube-system --version=1.15.7 -f deployments/cilium.yaml \
		cilium cilium/cilium > deployments/cilium-result.yaml

system:
	helm --kubeconfig=kubeconfig upgrade -i --namespace=kube-system --version=1.15.7 -f deployments/cilium.yaml \
		cilium cilium/cilium

	kubectl --kubeconfig=kubeconfig -n kube-system delete svc cilium-agent

	kubectl --kubeconfig=kubeconfig apply -f ../_deployments/vars/coredns-local.yaml

	helm --kubeconfig=kubeconfig upgrade -i --namespace=kube-system -f ../_deployments/vars/metrics-server.yaml \
		metrics-server metrics-server/metrics-server

	helm --kubeconfig=kubeconfig upgrade -i --namespace=kube-system -f deployments/talos-ccm.yaml \
		--set useDaemonSet=true \
		talos-cloud-controller-manager \
		oci://ghcr.io/siderolabs/charts/talos-cloud-controller-manager

deploy-csi:
	dd if=/dev/urandom bs=1 count=16 2>/dev/null | hexdump -e '"%00x"' > scw-csi-secret.secret
	kubectl --kubeconfig=kubeconfig create secret generic scw-csi-secret --from-file=encryptionPassphrase=scw-csi-secret.secret

	kubectl --kubeconfig=kubeconfig apply -f deployments/scaleway-csi.yaml
	kubectl --kubeconfig=kubeconfig apply -f deployments/scaleway-csi-node.yaml
	kubectl --kubeconfig=kubeconfig apply -f deployments/scaleway-storage.yaml
	rm -f scw-csi-secret.secret
