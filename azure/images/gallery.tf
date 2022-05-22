
data "azurerm_resource_group" "kubernetes" {
  name = var.project
}

resource "random_id" "images" {
  byte_length = 8
}

resource "azurerm_shared_image_gallery" "talos" {
  name                = random_id.images.hex
  resource_group_name = data.azurerm_resource_group.kubernetes.name
  location            = var.regions[0]
  description         = "Shared talos images.\nhttps://www.talos.dev/"

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_shared_image" "talos" {
  name                = "talos"
  gallery_name        = azurerm_shared_image_gallery.talos.name
  resource_group_name = data.azurerm_resource_group.kubernetes.name
  location            = var.regions[0]
  description         = "https://www.talos.dev"
  os_type             = "Linux"

  hyper_v_generation                  = "V2"
  accelerated_network_support_enabled = true
  # specialized                         = true

  identifier {
    publisher = var.project
    offer     = "Talos"
    sku       = "1.0-dev"
  }
}

resource "azurerm_storage_account" "images" {
  name                     = random_id.images.hex
  resource_group_name      = data.azurerm_resource_group.kubernetes.name
  location                 = var.regions[0]
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true

    container_delete_retention_policy {
      days = 1
    }
    delete_retention_policy {
      days = 1
    }
  }

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_storage_container" "images" {
  name                  = lower(var.project)
  storage_account_name  = azurerm_storage_account.images.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "talos" {
  name                   = "talos-amd64.vhd"
  storage_account_name   = azurerm_storage_account.images.name
  storage_container_name = azurerm_storage_container.images.name
  type                   = "Page"
  source                 = "${path.module}/disk.vhd"
}

resource "azurerm_image" "talos" {
  location            = var.regions[0]
  name                = "talos-amd64"
  resource_group_name = data.azurerm_resource_group.kubernetes.name
  hyper_v_generation  = "V2"

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized" # Specialized
    blob_uri = azurerm_storage_blob.talos.url
    caching  = "ReadOnly"
    size_gb  = 8
  }

  tags = merge(var.tags, { os = "talos" })
}

resource "azurerm_shared_image_version" "talos" {
  name                = "0.0.2"
  location            = var.regions[0]
  resource_group_name = data.azurerm_resource_group.kubernetes.name
  gallery_name        = azurerm_shared_image.talos.gallery_name
  image_name          = azurerm_shared_image.talos.name
  managed_image_id    = azurerm_image.talos.id

  target_region {
    name                   = var.regions[0]
    regional_replica_count = 1
    storage_account_type   = "Standard_LRS"
  }
}
