
data "azurerm_resource_group" "kubernetes" {
  name = var.resource_group
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
  for_each            = toset(var.arch)
  name                = "talos-${lower(each.key)}"
  gallery_name        = azurerm_shared_image_gallery.talos.name
  resource_group_name = data.azurerm_resource_group.kubernetes.name
  location            = var.regions[0]
  description         = "https://www.talos.dev"
  os_type             = "Linux"

  hyper_v_generation                  = "V2"
  architecture                        = each.key
  accelerated_network_support_enabled = lower(each.key) == "x64"
  # specialized                         = true

  identifier {
    publisher = var.name
    offer     = "Talos-${lower(each.key)}"
    sku       = "1.2-dev"
  }

  tags = merge(var.tags, { type = "infra" })
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
  name                  = lower(var.name)
  storage_account_name  = azurerm_storage_account.images.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "talos" {
  for_each               = toset(var.arch)
  name                   = "talos-${lower(each.key)}.vhd"
  storage_account_name   = azurerm_storage_account.images.name
  storage_container_name = azurerm_storage_container.images.name
  type                   = "Page"
  source                 = "${path.module}/disk-${lower(each.key)}.vhd"
  metadata = {
    md5 = filemd5("${path.module}/disk-${lower(each.key)}.vhd")
  }
}

resource "azurerm_image" "talos" {
  for_each            = { for name, k in azurerm_storage_blob.talos : name => k.url }
  location            = var.regions[0]
  name                = "talos-${lower(each.key)}"
  resource_group_name = data.azurerm_resource_group.kubernetes.name
  hyper_v_generation  = "V2"

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized" # Specialized/Generalized
    blob_uri = azurerm_storage_blob.talos[each.key].url
    caching  = "ReadOnly"
    size_gb  = 8
  }

  tags = merge(var.tags, { os = "talos" })
}

resource "azurerm_shared_image_version" "talos" {
  for_each            = { for name, k in azurerm_storage_blob.talos : name => k.url }
  name                = "1.2.0"
  location            = var.regions[0]
  resource_group_name = data.azurerm_resource_group.kubernetes.name
  gallery_name        = azurerm_shared_image.talos[each.key].gallery_name
  image_name          = azurerm_shared_image.talos[each.key].name
  managed_image_id    = azurerm_image.talos[each.key].id

  dynamic "target_region" {
    for_each = var.regions

    content {
      name                   = target_region.value
      regional_replica_count = 1
      storage_account_type   = "Standard_LRS"
    }
  }
}
