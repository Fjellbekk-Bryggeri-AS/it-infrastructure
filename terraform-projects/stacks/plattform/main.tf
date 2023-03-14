# =============================================================================
#  Plattform – nettbutikken til Fjellbekk Bryggeri AS
#  Levert av Nordavind IT AS, 2023.
#
#  Rulles ut ETTER nettverk og data. Leser begge via remote state.
# =============================================================================

provider "azurerm" {
  features {}

  resource_providers_to_register = ["Microsoft.Compute", "Microsoft.Network"]
}

locals {
  navn = "fjellbekk-${var.environment}"

  tags = {
    environment = var.environment
    project     = "fjellbekk"
    stack       = "plattform"
    managedby   = "terraform"
    keep        = "true"
  }
}

# --- Andre stacker -----------------------------------------------------------

data "terraform_remote_state" "nettverk" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.tfstate_resource_group_name
    storage_account_name = var.tfstate_storage_account_name
    container_name       = "tfstate"
    key                  = "fjellbekk/${var.environment}/nettverk.tfstate"
    use_azuread_auth     = true
  }
}

data "terraform_remote_state" "data" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.tfstate_resource_group_name
    storage_account_name = var.tfstate_storage_account_name
    container_name       = "tfstate"
    key                  = "fjellbekk/${var.environment}/data.tfstate"
    use_azuread_auth     = true
  }
}

# --- Webserver ---------------------------------------------------------------

resource "azurerm_resource_group" "plattform" {
  name     = "rg-${local.navn}-plattform"
  location = var.location
  tags     = local.tags
}

resource "azurerm_public_ip" "web" {
  name                = "pip-${local.navn}-web"
  location            = azurerm_resource_group.plattform.location
  resource_group_name = azurerm_resource_group.plattform.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.dns_label
  tags                = local.tags
}

resource "azurerm_network_interface" "web" {
  name                = "nic-${local.navn}-web"
  location            = azurerm_resource_group.plattform.location
  resource_group_name = azurerm_resource_group.plattform.name
  tags                = local.tags

  ip_configuration {
    name                          = "primar"
    subnet_id                     = data.terraform_remote_state.nettverk.outputs.subnet_ids["web"]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  name                  = "vm-${local.navn}-web"
  location              = azurerm_resource_group.plattform.location
  resource_group_name   = azurerm_resource_group.plattform.name
  size                  = var.vm_size
  network_interface_ids = [azurerm_network_interface.web.id]
  tags                  = local.tags

  admin_username                  = "nordavind"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "nordavind"
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

# --- Nettsiden ---------------------------------------------------------------
#
# Installerer nginx og legger ut index.html og health.json. Kjøres på nytt hver
# gang innholdet endres – uten at maskinen byttes ut.

locals {
  index_html = templatefile("${path.module}/nettside/index.html.tftpl", {
    miljo          = var.environment
    kampanjetekst  = var.kampanjetekst
    banner_url     = data.terraform_remote_state.data.outputs.banner_url
    nettside_versj = var.nettside_versjon
  })

  health_json = jsonencode({
    status   = "ok"
    miljo    = var.environment
    versjon  = var.nettside_versjon
    vm_size  = var.vm_size
    kampanje = var.kampanjetekst
  })

  installer = templatefile("${path.module}/nettside/installer.sh.tftpl", {
    index_b64  = base64encode(local.index_html)
    health_b64 = base64encode(local.health_json)
  })
}

resource "azurerm_virtual_machine_extension" "nettside" {
  name                 = "nettside"
  virtual_machine_id   = azurerm_linux_virtual_machine.web.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  tags                 = local.tags

  # timestamp endres bare når skriptet endres, og får da utvidelsen til å
  # kjøre skriptet på nytt.
  settings = jsonencode({
    timestamp = parseint(substr(sha1(local.installer), 0, 7), 16)
  })

  protected_settings = jsonencode({
    script = base64encode(local.installer)
  })
}
