environment = "prod"
location    = "norwayeast"

# Samme verdier som i shared/backend.hcl
tfstate_resource_group_name  = "rg-tfstate-tim"
tfstate_storage_account_name = "sttfstatetim123"

dns_label = "fjellbekk-bryggeri"
vm_size   = "Standard_D2s_v5"

# Ola Nordmann, Nordavind IT
admin_ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILWSG/hvuzuLDWZ2ZNYY8IJaYGfEDNpQN59vUvIVLwt7 ola.nordmann@nordavind-it.no"

kampanjetekst    = "Velkommen til vår nye nettbutikk!"
nettside_versjon = "1.0.0"
