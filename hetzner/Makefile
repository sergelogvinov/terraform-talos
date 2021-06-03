
prepare-image:
	ssh-keygen -f /.ssh/terraform -N '' -t rsa

	cd prepare
	terraform init
	terraform apply -auto-approve

create-config:
	talosctl gen config --output-dir _cfgs --with-docs=false --with-examples=false talos-k8s-hezner https://127.0.0.1:6443
	yq ea -P '. as $item ireduce ({}; . * $item )' _cfgs/controlplane.yaml templates/controlplane.yaml.tpl > templates/controlplane.yaml

create-controlplane:
	terraform init
	terraform apply -target=null_resource.controlplane_apply

create-infrastructure:
	terraform apply
