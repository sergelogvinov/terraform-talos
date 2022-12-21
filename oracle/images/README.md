# Upload images

Create the config file **terraform.tfvars** and add params.

```hcl
# Body of terraform.tfvars
```

```shell
wget https://github.com/siderolabs/talos/releases/download/v1.3.0/oracle-amd64.qcow2.xz
wget https://github.com/siderolabs/talos/releases/download/v1.3.0/oracle-arm64.qcow2.xz
xz -d oracle-amd64.qcow2.xz
xz -d oracle-arm64.qcow2.xz

terraform init && terraform apply -auto-approve
```
