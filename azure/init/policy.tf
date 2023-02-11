
# Source https://kubernetes-sigs.github.io/cloud-provider-azure/topics/azure-permissions/

resource "azurerm_role_definition" "ccm" {
  name              = "kubernetes-ccm"
  description       = "This is a kubernetes role for CCM, created via Terraform"
  scope             = data.azurerm_subscription.current.id
  assignable_scopes = [data.azurerm_subscription.current.id]

  permissions {
    actions = [
      # LoadBalancer
      "Microsoft.Network/loadBalancers/read",
      "Microsoft.Network/loadBalancers/backendAddressPools/read",
      "Microsoft.Network/publicIPAddresses/read",

      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Network/routeTables/read",
      "Microsoft.Network/routeTables/routes/read",

      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachineScaleSets/read",
      "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/read",
      "Microsoft.Compute/virtualMachineScaleSets/virtualmachines/instanceView/read",

      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/networkInterfaces/read",
      "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/networkInterfaces/ipconfigurations/publicipaddresses/read",

      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/read",
    ]
    not_actions = []
  }
}

resource "azurerm_role_definition" "csi" {
  name              = "kubernetes-csi"
  description       = "This is a kubernetes role for CSI, created via Terraform"
  scope             = data.azurerm_subscription.current.id
  assignable_scopes = [data.azurerm_subscription.current.id]

  permissions {
    actions = [
      "Microsoft.Storage/storageAccounts/delete",
      "Microsoft.Storage/storageAccounts/listKeys/action",
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.Storage/storageAccounts/write",
      "Microsoft.Storage/operations/read",

      "Microsoft.Compute/disks/delete",
      "Microsoft.Compute/disks/read",
      "Microsoft.Compute/disks/write",

      "Microsoft.Compute/snapshots/delete",
      "Microsoft.Compute/snapshots/read",
      "Microsoft.Compute/snapshots/write",

      "Microsoft.Compute/locations/DiskOperations/read",
      "Microsoft.Compute/locations/vmSizes/read",
      "Microsoft.Compute/locations/operations/read",

      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.Compute/virtualMachineScaleSets/read",
      "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/read",
      "Microsoft.Compute/virtualMachineScaleSets/virtualmachines/write",
      "Microsoft.Compute/virtualMachineScaleSets/virtualmachines/instanceView/read",
    ]
    not_actions = []
  }
}


resource "azurerm_role_definition" "scaler" {
  name              = "kubernetes-node-autoscaler"
  description       = "This is a kubernetes role for node autoscaler system, created via Terraform"
  scope             = data.azurerm_subscription.current.id
  assignable_scopes = [data.azurerm_subscription.current.id]

  permissions {
    actions = [
      "Microsoft.Compute/disks/read",

      "Microsoft.Compute/locations/DiskOperations/read",
      "Microsoft.Compute/locations/vmSizes/read",
      "Microsoft.Compute/locations/operations/read",

      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachineScaleSets/read",
      "Microsoft.Compute/virtualMachineScaleSets/write",
      "Microsoft.Compute/virtualMachineScaleSets/skus/read",
      "Microsoft.Compute/virtualMachineScaleSets/vmSizes/read",
      "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/read",
      "Microsoft.Compute/virtualMachineScaleSets/virtualmachines/write",
      "Microsoft.Compute/virtualMachineScaleSets/virtualmachines/instanceView/read",

      "Microsoft.Compute/virtualMachineScaleSets/scale/action",
      "Microsoft.Compute/virtualMachineScaleSets/delete/action",
    ]
    not_actions = []
  }
}
