# Provider configurations for Azure

provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  use_cli = true
}

provider "azuread" {
  use_cli = true
}

provider "azapi" {
  # Usa la misma autenticación que azurerm (Azure CLI)
}
