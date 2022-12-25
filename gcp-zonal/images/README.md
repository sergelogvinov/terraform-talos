# Upload images

```hcl
# Body of terraform.tfvars
```

```shell
wget https://github.com/siderolabs/talos/releases/download/v1.3.0/gcp-amd64.tar.gz
wget https://github.com/siderolabs/talos/releases/download/v1.3.0/gcp-arm64.tar.gz

terraform init && terraform apply -auto-approve
```
