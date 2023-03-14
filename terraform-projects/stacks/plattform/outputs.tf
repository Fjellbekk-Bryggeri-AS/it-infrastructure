output "url" {
  value       = "http://${azurerm_public_ip.web.fqdn}/"
  description = "Adressen til nettbutikken."
}

output "health_url" {
  value       = "http://${azurerm_public_ip.web.fqdn}/health.json"
  description = "Helsesjekken som dashboardet leser."
}

output "public_ip" {
  value       = azurerm_public_ip.web.ip_address
  description = "Offentlig IP-adresse til webserveren."
}
