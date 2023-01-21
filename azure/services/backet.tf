
resource "random_id" "backet" {
  byte_length = 8
}

resource "azurerm_storage_account" "backet" {
  name                     = random_id.backet.hex
  resource_group_name      = local.resource_group
  location                 = local.regions[0]
  account_tier             = "Standard"
  account_replication_type = "LRS"

  shared_access_key_enabled        = false
  cross_tenant_replication_enabled = false
  allow_nested_items_to_be_public  = false

  blob_properties {
    versioning_enabled = false
  }

  tags = var.tags
}

resource "azurerm_storage_container" "backup" {
  name                  = "backup"
  storage_account_name  = azurerm_storage_account.backet.name
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "backup" {
  storage_account_id = azurerm_storage_account.backet.id

  rule {
    name    = "cleanup"
    enabled = true
    filters {
      prefix_match = ["${azurerm_storage_container.backup.name}/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 7
      }
    }
  }
}

resource "azurerm_role_assignment" "terraform" {
  scope                = azurerm_storage_container.backup.resource_manager_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = data.azurerm_client_config.terraform.object_id
}

resource "azurerm_role_assignment" "backup" {
  scope                = azurerm_storage_container.backup.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.principal
}
