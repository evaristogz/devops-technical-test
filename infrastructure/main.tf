# Terraform Infrastructure for Azure E-commerce Application

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
  }

  ### Descomentar un nivel para usar el backend de Azure Storage (previo haber creado los recursos necesarios)
  # backend "azurerm" {
  #     # TODO: Configure remote state backend
  #     # Uncomment and configure the following:
  #     resource_group_name  = "rg-terraform-state"
  #     storage_account_name = "tfstatedevops2025"
  #     container_name       = "tfstate"
  #     key                  = "ecommerce-app.tfstate"
  #   }
  # }
  ###

  ## Comentar si se usa backend "azurerm"
  cloud {
    organization = "EGZ-TC"

    workspaces {
      name = "ecommerce-dev"
    }
  }
  ##
}

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

# Data sources
data "azurerm_client_config" "current" {}



# TODO: Create Resource Group
# Name: "rg-${local.name_prefix}"
# Location: var.location
# Tags: local.common_tags
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}



# TODO: Create Virtual Network
# Name: "vnet-${local.name_prefix}" 
# Address space: ["10.0.0.0/16"]
# Subnets needed:
# - AKS subnet: 10.0.1.0/24
# - Database subnet: 10.0.2.0/24  
# - Application Gateway subnet: 10.0.3.0/24
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space
  tags                = local.common_tags
}

# Subnet para AKS
resource "azurerm_subnet" "aks" {
  name                 = "subnet-aks-${local.name_prefix}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_subnet_address_prefix]
}

# Subnet para database
resource "azurerm_subnet" "database" {
  name                 = "subnet-db-${local.name_prefix}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.db_subnet_address_prefix]
}

# Subnet para Application Gateway
resource "azurerm_subnet" "app_gateway" {
  name                 = "subnet-agw-${local.name_prefix}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.agw_subnet_address_prefix]
}



# TODO: Create Network Security Groups
# - NSG for AKS subnet with appropriate rules
# - NSG for database subnet (restrictive)
# - NSG for Application Gateway subnet

# NSG para AKS
resource "azurerm_network_security_group" "aks" {
  name                = "nsg-aks-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# Regla NSG - Permitir tráfico desde Application Gateway
resource "azurerm_network_security_rule" "aks_from_agw" {
  name                        = "AllowFromAppGateway"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = var.agw_subnet_address_prefix
  destination_address_prefix  = var.aks_subnet_address_prefix
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# Regla NSG - Permitir tráfico salida del puerto 5432 de PostgreSQL
resource "azurerm_network_security_rule" "aks_to_database" {
  name                        = "AllowToDatabase"
  priority                    = 101
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = var.aks_subnet_address_prefix
  destination_address_prefix  = var.db_subnet_address_prefix
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# Asociar NSG con la subnet de AKS
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}



# NSG para Database
resource "azurerm_network_security_group" "database" {
  name                = "nsg-db-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# Regla NSG - Permitir tráfico de entrada desde AKS solo puerto 5432 PostgreSQL
resource "azurerm_network_security_rule" "database_from_aks" {
  name                        = "AllowFromAKS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = var.aks_subnet_address_prefix
  destination_address_prefix  = var.db_subnet_address_prefix
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.database.name
}

# Asociar NSG con la subnet de Database
resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id
}



# NSG para Application Gateway
resource "azurerm_network_security_group" "app_gateway" {
  name                = "nsg-agw-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# Regla NSG - Permitir HTTP desde internet
resource "azurerm_network_security_rule" "agw_http" {
  name                        = "AllowHTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = var.agw_subnet_address_prefix
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.app_gateway.name
}

# Regla NSG - Permitir HTTPS desde internet
resource "azurerm_network_security_rule" "agw_https" {
  name                        = "AllowHTTPS"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = var.agw_subnet_address_prefix
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.app_gateway.name
}

# Asociar NSG con la subnet de Application Gateway
resource "azurerm_subnet_network_security_group_association" "app_gateway" {
  subnet_id                 = azurerm_subnet.app_gateway.id
  network_security_group_id = azurerm_network_security_group.app_gateway.id
}

# TODO: Create Azure Container Registry
# Requirements:
# - Premium SKU for geo-replication
# - Admin user disabled (use managed identity)
# - Integration with AKS cluster
resource "azurerm_container_registry" "acr" {
  name                = "acr${replace(local.name_prefix, "-", "")}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = var.acr_admin_enabled
  tags                = local.common_tags
}



# TODO: Create AKS Cluster
# Requirements:
# - System node pool: 2 nodes, Standard_DS2_v2
# - User node pool: 3 nodes, auto-scaling (min 2, max 5)
# - Managed Identity enabled
# - Azure CNI networking
# - Integration with ACR
# - Azure Monitor enabled

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "aks-${local.name_prefix}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name            = "system"
    node_count      = var.aks_system_node_count
    vm_size         = var.aks_vm_size
    os_disk_size_gb = var.aks_os_disk_size_gb
    vnet_subnet_id  = azurerm_subnet.aks.id
    type            = "VirtualMachineScaleSets"
    tags            = local.common_tags
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    service_cidr      = var.aks_service_cidr
    dns_service_ip    = var.aks_dns_service_ip
    load_balancer_sku = var.aks_load_balancer_sku
  }

  tags = local.common_tags
}

# Nodo adicional para cargas de usuario
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  # node_count eliminado para autoescalado
  vm_size         = var.aks_vm_size
  os_disk_size_gb = var.aks_os_disk_size_gb
  vnet_subnet_id  = azurerm_subnet.aks.id

  min_count = var.aks_min_count
  max_count = var.aks_max_count

  tags = local.common_tags
}


# ACR Pull Role Assignment para AKS
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}



# TODO: Create Azure Key Vault
# Requirements:
# - Soft delete enabled
# - Access policies for AKS managed identity
# - Network access from AKS subnet only
# - Enable for template deployment

resource "azurerm_key_vault" "main" {
  name                = "kv-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  # soft_delete_enabled       = true # Deprecado 
  purge_protection_enabled = false
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = [
      azurerm_subnet.aks.id
    ]
  }
  tags = local.common_tags
}

# Permitir acceso a la identidad de AKS (Managed Identity) para secretos
resource "azurerm_key_vault_access_policy" "aks" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_kubernetes_cluster.main.identity[0].principal_id

  secret_permissions = [
    "Get", "List"
  ]
  certificate_permissions = []
  key_permissions         = []
  storage_permissions     = []
}



# TODO: Create Log Analytics Workspace
# Requirements:
# - Retention: 30 days
# - Integration with AKS cluster
# - Application Insights component
# Log Analytics Workspace para monitorización

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days

  tags = local.common_tags
}

# Application Insights para monitorización
resource "azurerm_application_insights" "main" {
  name                = "appinsights-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id

  tags = local.common_tags
}



# TODO: Create Azure Database for PostgreSQL Flexible Server
# Requirements:
# - Version 14
# - Burstable SKU (B1ms to start)
# - Private endpoint in database subnet
# - Firewall rules for AKS subnet
# - Backup retention: 7 days

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${local.name_prefix}"
  location               = azurerm_resource_group.main.location
  resource_group_name    = azurerm_resource_group.main.name
  administrator_login    = var.postgres_admin_username
  administrator_password = var.postgres_admin_password
  sku_name               = var.postgres_sku_name
  version                = var.postgres_version
  storage_mb             = var.postgres_storage_mb
  backup_retention_days  = var.postgres_backup_retention_days
  zone                   = "1"
  delegated_subnet_id    = azurerm_subnet.database.id
  tags                   = local.common_tags
}

# Firewall rule para permitir acceso desde AKS
resource "azurerm_postgresql_flexible_server_firewall_rule" "aks" {
  name             = "allow-aks"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "10.0.1.0"
  end_ip_address   = "10.0.1.255"
}



# TODO: Create Application Gateway
# Requirements:
# - Standard_v2 SKU
# - WAF enabled
# - SSL termination
# - Backend pool for AKS ingress
# - Health probes configuration

resource "azurerm_application_gateway" "main" {
  backend_address_pool {
    name  = "aks-backend-pool"
    fqdns = ["ingress-aks.local"]
  }

  backend_http_settings {
    name                                = "http-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    pick_host_name_from_backend_address = false
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "aks-backend-pool"
    backend_http_settings_name = "http-settings"
  }
  name                = "agw-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku {
    name     = var.app_gateway_sku_name
    tier     = var.app_gateway_sku_tier
    capacity = var.app_gateway_capacity
  }
  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.app_gateway.id
  }
  frontend_port {
    name = "http"
    port = 80
  }
  frontend_port {
    name = "https"
    port = 443
  }
  frontend_ip_configuration {
    name                          = "frontend-ip"
    subnet_id                     = azurerm_subnet.app_gateway.id
    private_ip_address_allocation = "Dynamic"
  }
  frontend_ip_configuration {
    name                 = "public-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }
  frontend_ip_configuration {
    name                          = "private-ip"
    subnet_id                     = azurerm_subnet.app_gateway.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.3.10"
  }
  frontend_port {
    name = "http"
    port = 80
  }
  frontend_port {
    name = "https"
    port = 443
  }
  frontend_ip_configuration {
    name                          = "frontend-ip"
    subnet_id                     = azurerm_subnet.app_gateway.id
    private_ip_address_allocation = "Dynamic"
  }
  frontend_ip_configuration {
    name                 = "public-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }
  frontend_ip_configuration {
    name                          = "private-ip"
    subnet_id                     = azurerm_subnet.app_gateway.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.3.10"
  }

  tags = local.common_tags
}

# Public IP para Application Gateway
resource "azurerm_public_ip" "appgw" {
  name                = "pip-agw-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}



# TODO: Create Storage Account for Azure Files
# Requirements:
# - Standard_LRS replication
# - File share for application uploads
# - Private endpoint in AKS subnet

resource "azurerm_storage_account" "main" {
  name                     = "st${replace(local.name_prefix, "-", "")}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

# File share para uploads
resource "azurerm_storage_share" "uploads" {
  name               = "${var.project_name}-uploads"
  storage_account_id = azurerm_storage_account.main.id
  quota              = 10 # GB
}