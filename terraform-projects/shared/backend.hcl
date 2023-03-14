# Adressen til state-lagringen. Felles for alle stacker og begge miljøer.
# `key` settes per stack og miljø ved init – se scripts/kjor.sh.

resource_group_name  = "rg-tfstate-tim"
storage_account_name = "sttfstatetim123"
container_name       = "tfstate"
use_azuread_auth     = true
