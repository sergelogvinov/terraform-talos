# Upload OS image to azure Gallery

```hcl
# Body of terraform.tfvars

project         = "<name of resource group>"
subscription_id = "<subscription id>"


# Zones, fist is main zone
regions         = ["uksouth", "ukwest", "westeurope"]
```

## Init and upload images

```shell
wget -q https://github.com/siderolabs/talos/releases/download/v1.4.5/azure-amd64.tar.gz
tar -xzf azure-amd64.tar.gz && mv disk.vhd disk-x64.vhd

wget -q https://github.com/siderolabs/talos/releases/download/v1.4.5/azure-arm64.tar.gz
tar -xzf azure-arm64.tar.gz && mv disk.vhd disk-arm64.vhd

terraform init && terraform apply
```

## Upgrade images

```shell
terraform taint 'azurerm_storage_blob.talos["x64"]'
terraform taint 'azurerm_storage_blob.talos["Arm64"]'
terraform apply
```
