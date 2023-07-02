# Upload images

Create the config file **terraform.tfvars** and add params.

```hcl
# Body of terraform.tfvars

# Regions to use
regions          = ["GRA7", "GRA9"]
```

```shell
wget https://github.com/siderolabs/talos/releases/download/v1.4.6/openstack-amd64.tar.gz
tar -xzf openstack-amd64.tar.gz

terraform init && terraform apply -auto-approve
```
