# Terraform version and required providers
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.00"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.00"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.00" # 3.0.1 la considero demasiado nueva
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.00"
    }
  }

  ### Backend configuration ###
  # Opción 1: Azure Storage backend.
  # Descomentar para usar (previo haber creado los recursos necesarios)
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "tfstatedevops2025"
  #   container_name       = "tfstate"
  #   key                  = "ecommerce-app.tfstate"
  # }

  # Opción 2: HCP Terraform / Terraform Cloud (actualmente en uso)
  cloud {
    organization = "EGZ-TC"
    workspaces {
      name = "ecommerce-dev"
    }
  }
}
