environment = "test"
location    = "norwayeast"

# Samme verdier som i shared/backend.hcl
tfstate_resource_group_name  = "rg-tfstate-tim"
tfstate_storage_account_name = "sttfstatetim123"

dns_label = "fjellbekk-bryggeri-test"
vm_size   = "Standard_B2als_v2"

# Fjellbekk Bryggeri, Plattform-teamet (byttet 22.10.2026, #21)
admin_ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAZ1ucvzptPbbVug2w3JcL9njzQ8ht+2sX/bFXrdE5Qv plattform@fjellbekk-bryggeri.no"

kampanjetekst    = "Høstbrygg 2026 er her! Fri frakt over 500 kr."
nettside_versjon = "2.3.0"
