#

REGISTRY ?= ghcr.io/sergelogvinov
SYNCARGS ?= --multi-arch=all

###

KUBERNETES ?= 1.27.3
PAUSE ?= 3.8
ETCD ?= 3.5.9
COREDNS ?= 1.10.1
CILIUM ?= 1.12.7
FLUENTBIT ?= 2.1.6
NODEEXPORTER ?= 1.6.0

################################################################################

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

images-sync:
	@skopeo copy $(SYNCARGS) --override-os=linux \
		docker://registry.k8s.io/kube-apiserver:v$(KUBERNETES) docker://$(REGISTRY)/kube-apiserver:v$(KUBERNETES)
	@skopeo copy $(SYNCARGS) --override-os=linux \
		docker://registry.k8s.io/kube-controller-manager:v$(KUBERNETES) docker://$(REGISTRY)/kube-controller-manager:v$(KUBERNETES)
	@skopeo copy $(SYNCARGS) --override-os=linux \
		docker://registry.k8s.io/kube-scheduler:v$(KUBERNETES) docker://$(REGISTRY)/kube-scheduler:v$(KUBERNETES)
	@skopeo copy $(SYNCARGS) --override-os=linux \
		docker://ghcr.io/siderolabs/kubelet:v$(KUBERNETES) docker://$(REGISTRY)/kubelet:v$(KUBERNETES)

	@skopeo copy $(SYNCARGS) --override-os=linux \
		docker://registry.k8s.io/pause:$(PAUSE) docker://$(REGISTRY)/pause:$(PAUSE)
	@skopeo copy $(SYNCARGS) --override-os=linux \
		docker://gcr.io/etcd-development/etcd:v$(ETCD) docker://$(REGISTRY)/etcd:v$(ETCD)
	@skopeo copy $(SYNCARGS) --override-os=linux \
		docker://coredns/coredns:$(COREDNS) docker://$(REGISTRY)/coredns:$(COREDNS)

	@skopeo copy $(SYNCARGS) --override-os=linux \
		docker://quay.io/cilium/cilium:v$(CILIUM) docker://$(REGISTRY)/cilium:v$(CILIUM)
	@skopeo copy $(SYNCARGS) --override-os=linux \
		docker://fluent/fluent-bit:$(FLUENTBIT) docker://$(REGISTRY)/fluent-bit:$(FLUENTBIT)
	@skopeo copy $(SYNCARGS) --override-os=linux \
		docker://quay.io/prometheus/node-exporter:v$(NODEEXPORTER) docker://$(REGISTRY)/node-exporter:v$(NODEEXPORTER)
