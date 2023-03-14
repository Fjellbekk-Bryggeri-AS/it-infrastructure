terraform {
  required_version = ">= 1.16.0"

  # Verdiene kommer fra shared/backend.hcl og -backend-config="key=..." ved init.
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.4"
    }
  }
}
