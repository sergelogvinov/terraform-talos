# Upload images

Create the config file **terraform.tfvars** and add params.
About image_metadata.json https://www.oracle.com/docs/tech/oracle-private-cloud-appliance-x9-2-workload-import.pdf

```hcl
# Body of terraform.tfvars
compartment_ocid = "ocid1.compartment.oc1.."
tenancy_ocid     = "ocid1.tenancy.oc1.."

user_ocid   = "ocid1.user.oc1..aaaaaaaaxxxxxx"
fingerprint = "ee:7f:67:00:e7:19:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
key_file    = "~/.oci/oci_api_key.pem"
```

```shell
wget https://github.com/siderolabs/talos/releases/download/v1.3.4/oracle-amd64.qcow2.xz
wget https://github.com/siderolabs/talos/releases/download/v1.3.4/oracle-arm64.qcow2.xz
xz -d oracle-amd64.qcow2.xz
xz -d oracle-arm64.qcow2.xz

cp image_metadata_amd64.json image_metadata.json
tar zcf oracle-amd64.oci oracle-amd64.qcow2 image_metadata.json

cp image_metadata_arm64.json image_metadata.json
tar zcf oracle-arm64.oci oracle-arm64.qcow2 image_metadata.json

terraform init && terraform apply -auto-approve
```
