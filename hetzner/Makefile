
CLUSTERNAME := "talos-k8s-hetzner"
CPFIRST := ${shell terraform output -raw controlplane_firstnode 2>/dev/null}
ENDPOINT := ${shell terraform output -raw controlplane_firstnode 2>/dev/null}
ifeq ($(ENDPOINT),)
ENDPOINT := 127.0.0.1
else ifneq (,$(findstring Warning,${ENDPOINT}))
ENDPOINT := 127.0.0.1
endif

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean: ## Clean all
	terraform destroy -auto-approve
	rm -rf .terraform.lock.hcl .terraform/ terraform.tfstate terraform.tfstate.backup
	rm -f kubeconfig terraform.tfvars.sops.json

prepare:
	@[ -f ~/.ssh/terraform ] || ssh-keygen -f ~/.ssh/terraform -N '' -t rsa

create-config: ## Genereate talos configs
	talosctl gen config --output-dir _cfgs --with-docs=false --with-examples=false ${CLUSTERNAME} https://${ENDPOINT}:6443
	talosctl --talosconfig _cfgs/talosconfig config endpoint ${ENDPOINT}

create-templates:
	@echo 'podSubnets: "10.32.0.0/12,fd40:10:32::/64"'         >  _cfgs/tfstate.vars
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
	@sops --encrypt --input-type=yaml --output-type=yaml _cfgs/talosconfig       > _cfgs/talosconfig.sops.yaml
	@sops --encrypt --input-type=yaml --output-type=yaml _cfgs/controlplane.yaml > _cfgs/controlplane.sops.yaml

create-lb: ## Create load balancer
	terraform init
	terraform apply -auto-approve -target=hcloud_floating_ip.api -target=hcloud_load_balancer.api
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

helm-repos: ## add helm repos
	helm repo add hcloud               https://charts.hetzner.cloud
	helm repo add autoscaler           https://kubernetes.github.io/autoscaler
	helm repo update

system-static:
	helm template --namespace=kube-system -f deployments/talos-ccm.yaml \
		--set useDaemonSet=true \
		talos-cloud-controller-manager \
		oci://ghcr.io/siderolabs/charts/talos-cloud-controller-manager > deployments/talos-cloud-controller-manager-result.yaml

	helm template --namespace=kube-system -f deployments/hcloud-ccm.yaml \
		hcloud-cloud-controller-manager hcloud/hcloud-cloud-controller-manager > deployments/hcloud-cloud-controller-manager-result.yaml

	helm template --namespace=kube-system -f deployments/hcloud-autoscaler.yaml cluster-autoscaler-hcloud \
		autoscaler/cluster-autoscaler > deployments/hcloud-autoscaler-result.yaml

	helm template --namespace=kube-system -f deployments/hcloud-csi.yaml hcloud-csi \
		hcloud/hcloud-csi > deployments/hcloud-csi-result.yaml

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

	base64 -i _cfgs/worker-as.yaml > _cfgs/worker-as.yaml.base64
	kubectl --kubeconfig=kubeconfig -n kube-system create secret generic hcloud-init --from-file=worker=_cfgs/worker-as.yaml.base64

deploy-csi:
	dd if=/dev/urandom bs=1 count=16 2>/dev/null | hexdump -e '"%00x"' > hcloud-csi-secret.secret
	kubectl --kubeconfig=kubeconfig create secret generic hcloud-csi-secret --from-file=encryptionPassphrase=hcloud-csi-secret.secret
	rm -f hcloud-csi-secret.secret

	kubectl --kubeconfig=kubeconfig apply -f deployments/hcloud-csi-result.yaml
