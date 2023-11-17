# OracleCloud

1. Upload the talos image to the cloud
2. Create networks
3. Launch the loadbalancer
4. Launch the controlplane
5. Scale the cluster

## Create compartment (optional)

First you need to prepare your compartment:

```shell
cd init
terraform init
terraform apply
```

It creats:

* compartment
* terraform account
* resources tags
* identity policy for terraform and CCM

## Upload images

```shell
./scripts/download

terraform init
terraform apply
```

## Create networks

* creates networks by zones and for zonal loadbalancer
* creates NAT for private networks
* creates security group and security list

```shell
make create-network
```

## Launch the cluster

### Create the loadbalancer

```shell
make create-lb
```

### Generate Talos configs

```shell
make create-config create-templates
```

* Check file ```terraform.tfvars.json```
* Create the ```terraform.tfvars``` like this

```tf
controlplane = {
  count = 1
  type  = "VM.Standard.E4.Flex"
  ocpus = 1
  memgb = 4
}

instances = {
  "jNdv:eu-amsterdam-1-AD-1" = {
    web_count             = 1,
    web_instance_shape    = "VM.Standard.E2.1.Micro",
    web_instance_ocpus    = 1,
    web_instance_memgb    = 1,
    worker_count          = 1,
    worker_instance_shape = "VM.Standard.E2.1.Micro",
    worker_instance_ocpus = 1,
    worker_instance_memgb = 1,
  },
}
```

### Bootstrap cluster

```shell
terraform apply
```
