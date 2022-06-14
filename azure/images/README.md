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
terraform init && terraform apply
```
