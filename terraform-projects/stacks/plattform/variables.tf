variable "environment" {
  type        = string
  description = "Miljø: test eller prod."

  validation {
    condition     = contains(["test", "prod"], var.environment)
    error_message = "environment må være test eller prod."
  }
}

variable "location" {
  type        = string
  description = "Azure-region."
}

variable "tfstate_resource_group_name" {
  type        = string
  description = "Ressursgruppa state-kontoen ligger i. Samme verdi som i shared/backend.hcl."
}

variable "tfstate_storage_account_name" {
  type        = string
  description = "State-kontoen. Samme verdi som i shared/backend.hcl."
}

variable "dns_label" {
  type        = string
  description = "DNS-navn for nettsiden: <dns_label>.<region>.cloudapp.azure.com"
}

variable "vm_size" {
  type        = string
  description = "Størrelse på webserveren."
}

variable "admin_ssh_public_key" {
  type        = string
  description = "Offentlig SSH-nøkkel for admin-brukeren."
}

variable "kampanjetekst" {
  type        = string
  description = "Teksten som vises øverst på forsiden."
}

variable "nettside_versjon" {
  type        = string
  description = "Versjonsnummer som vises i bunnteksten og i health.json."
}
