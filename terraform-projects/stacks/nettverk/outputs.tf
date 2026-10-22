# Leses av plattform-stacken via terraform_remote_state. Ikke endre navnene.

output "subnet_ids" {
  value = {
    for navn, subnet in azurerm_subnet.subnet : navn => subnet.id
  }
  description = "Subnett-ID per navn."
}

output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "ID til det virtuelle nettverket."
}

output "resource_group_name" {
  value       = azurerm_resource_group.nett.name
  description = "Ressursgruppa nettverket ligger i."
}
