# Terraform Infrastructure for Azure E-commerce Application

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.40"
    }
  }
  
  backend "azurerm" {
    # TODO: Configure remote state backend
    # Uncomment and configure the following:
    # resource_group_name  = "rg-terraform-state"
    # storage_account_name = "tfstatedevops2025"
    # container_name       = "tfstate"
    # key                  = "ecommerce-app.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# TODO: Create Resource Group
# Name: "rg-${local.name_prefix}"
# Location: var.location
# Tags: local.common_tags

# TODO: Create Virtual Network
# Name: "vnet-${local.name_prefix}" 
# Address space: ["10.0.0.0/16"]
# Subnets needed:
# - AKS subnet: 10.0.1.0/24
# - Database subnet: 10.0.2.0/24  
# - Application Gateway subnet: 10.0.3.0/24

# TODO: Create Network Security Groups
# - NSG for AKS subnet with appropriate rules
# - NSG for database subnet (restrictive)
# - NSG for Application Gateway subnet

# TODO: Create AKS Cluster
# Requirements:
# - System node pool: 2 nodes, Standard_DS2_v2
# - User node pool: 3 nodes, auto-scaling (min 2, max 5)
# - Managed Identity enabled
# - Azure CNI networking
# - Integration with ACR
# - Azure Monitor enabled

# TODO: Create Azure Container Registry
# Requirements:
# - Premium SKU for geo-replication
# - Admin user disabled (use managed identity)
# - Integration with AKS cluster

# TODO: Create Azure Key Vault
# Requirements:
# - Soft delete enabled
# - Access policies for AKS managed identity
# - Network access from AKS subnet only
# - Enable for template deployment

# TODO: Create Log Analytics Workspace
# Requirements:
# - Retention: 30 days
# - Integration with AKS cluster
# - Application Insights component

# TODO: Create Azure Database for PostgreSQL Flexible Server
# Requirements:
# - Version 14
# - Burstable SKU (B1ms to start)
# - Private endpoint in database subnet
# - Firewall rules for AKS subnet
# - Backup retention: 7 days

# TODO: Create Application Gateway
# Requirements:
# - Standard_v2 SKU
# - WAF enabled
# - SSL termination
# - Backend pool for AKS ingress
# - Health probes configuration

# TODO: Create Storage Account for Azure Files
# Requirements:
# - Standard_LRS replication
# - File share for application uploads
# - Private endpoint in AKS subnet