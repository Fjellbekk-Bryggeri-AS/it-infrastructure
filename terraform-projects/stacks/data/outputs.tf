# Leses av plattform-stacken via terraform_remote_state. Ikke endre navnene.

output "storage_account_name" {
  value       = azurerm_storage_account.data.name
  description = "Navnet på storage-kontoen."
}

output "banner_url" {
  value       = "${azurerm_storage_account.data.primary_blob_endpoint}${azurerm_storage_container.kampanje.name}/${azurerm_storage_blob.banner.name}"
  description = "Offentlig URL til kampanjebanneret. Nettsiden lenker hit."
}

output "resource_group_name" {
  value       = azurerm_resource_group.data.name
  description = "Ressursgruppa data ligger i."
}
