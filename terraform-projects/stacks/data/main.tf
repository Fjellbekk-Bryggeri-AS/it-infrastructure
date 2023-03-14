# =============================================================================
#  Data – Fjellbekk Bryggeri AS
#  Levert av Nordavind IT AS, 2023.
# =============================================================================

provider "azurerm" {
  features {}

  resource_providers_to_register = ["Microsoft.Storage"]
}

locals {
  navn = "fjellbekk-${var.environment}"

  tags = {
    environment = var.environment
    project     = "fjellbekk"
    stack       = "data"
    managedby   = "terraform"
    keep        = "true"
  }
}

resource "azurerm_resource_group" "data" {
  name     = "rg-${local.navn}-data"
  location = var.location
  tags     = local.tags
}

# Storage-navn må være globalt unike.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "data" {
  name                = "stfjellbekk${var.environment}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.data.name
  location            = azurerm_resource_group.data.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  # Markedsavdelingen må kunne lenke rett til kampanjebildene.
  allow_nested_items_to_be_public = true

  tags = local.tags
}

# Bilder til nettsiden. Offentlig, så nettleseren kan hente dem direkte.
resource "azurerm_storage_container" "kampanje" {
  name                  = "kampanje"
  storage_account_id    = azurerm_storage_account.data.id
  container_access_type = "blob"
}

# Ordreeksporter fra nettbutikken.
resource "azurerm_storage_container" "ordrer" {
  name                  = "ordrer"
  storage_account_id    = azurerm_storage_account.data.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "banner" {
  name                 = "banner.svg"
  storage_container_id = azurerm_storage_container.kampanje.id
  type                 = "Block"
  content_type         = "image/svg+xml"
  source               = "${path.module}/banner.svg"
  content_md5          = filemd5("${path.module}/banner.svg")
}
