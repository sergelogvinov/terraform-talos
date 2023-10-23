#
REGISTRY ?= ghcr.io/siderolabs
TAG ?= 1.5.4

clean:
	rm -f nocloud-*.qcow2.xz
	rm -f nocloud-*.qcow2

init:
	packer init -upgrade .

release:
	packer build -only=release.proxmox.talos .

images: clean
	docker run --rm -i -v /dev:/dev --privileged $(REGISTRY)/imager:v$(TAG) oracle \
		--extra-kernel-arg talos.dashboard.disabled=1 --platform nocloud --arch amd64 --tar-to-stdout | tar xz
	xz -d nocloud-amd64.qcow2.xz
