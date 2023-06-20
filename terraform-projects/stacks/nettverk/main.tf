# =============================================================================
#  Nettverk – Fjellbekk Bryggeri AS
#  Levert av Nordavind IT AS, 2023. Sist endret 2024.
# =============================================================================

provider "azurerm" {
  features {}

  resource_providers_to_register = ["Microsoft.Network"]
}

locals {
  navn = "fjellbekk-${var.environment}"

  tags = {
    environment = var.environment
    project     = "fjellbekk"
    stack       = "nettverk"
    managedby   = "terraform"

    # Tenanten rydder bort ressursgrupper uten keep=true hver natt.
    keep = "true"
  }
}

resource "azurerm_resource_group" "nett" {
  name     = "rg-${local.navn}-nett"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.navn}"
  location            = azurerm_resource_group.nett.location
  resource_group_name = azurerm_resource_group.nett.name
  address_space       = [var.address_space]
  tags                = local.tags
}

# --- Subnett -----------------------------------------------------------------

resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.nett.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 1)]
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.nett.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 2)]
}

resource "azurerm_subnet" "data" {
  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.nett.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 3)]
}

# --- Brannmur for web --------------------------------------------------------

resource "azurerm_network_security_group" "web" {
  name                = "nsg-${local.navn}-web"
  location            = azurerm_resource_group.nett.location
  resource_group_name = azurerm_resource_group.nett.name
  tags                = local.tags

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}
