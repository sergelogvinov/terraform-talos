#
REGISTRY ?= ghcr.io/siderolabs
TAG ?= 1.6.7

clean:
	rm -rf .terraform.lock.hcl .terraform/
	rm -f oracle-*.qcow2
	rm -f oracle-*.oci
	rm -f image_metadata.json

init:
	terraform init -upgrade

images: clean
	docker run --rm -i -v /dev:/dev --privileged $(REGISTRY)/imager:v$(TAG) oracle \
		--extra-kernel-arg talos.dashboard.disabled=1 --platform oracle --arch amd64 --tar-to-stdout | tar xz
	xz -d oracle-amd64.qcow2.xz
	cp image_metadata_amd64.json image_metadata.json
	tar zcf oracle-amd64.oci oracle-amd64.qcow2 image_metadata.json

	docker run --rm -i -v /dev:/dev --privileged $(REGISTRY)/imager:v$(TAG) oracle \
		--extra-kernel-arg talos.dashboard.disabled=1 --platform oracle --arch arm64 --tar-to-stdout | tar xz
	xz -d oracle-arm64.qcow2.xz
	cp image_metadata_arm64.json image_metadata.json
	tar zcf oracle-arm64.oci oracle-arm64.qcow2 image_metadata.json

images-factory: clean
	wget -O oracle-amd64.qcow2.xz https://factory.talos.dev/image/6d423353cba6ef7d56d5a818fff27caf23f32b90cf271eada90f706141a84ec0/v$(TAG)/oracle-amd64.qcow2.xz
	xz -d oracle-amd64.qcow2.xz
	cp image_metadata_amd64.json image_metadata.json
	tar zcf oracle-amd64.oci oracle-amd64.qcow2 image_metadata.json

	wget -O oracle-arm64.qcow2.xz https://factory.talos.dev/image/6d423353cba6ef7d56d5a818fff27caf23f32b90cf271eada90f706141a84ec0/v$(TAG)/oracle-arm64.qcow2.xz
	xz -d oracle-arm64.qcow2.xz
	cp image_metadata_arm64.json image_metadata.json
	tar zcf oracle-arm64.oci oracle-arm64.qcow2 image_metadata.json

images-update:
	terraform apply -var="release=v$(TAG)"
