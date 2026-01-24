# Output values for Azure E-commerce Infrastructure

# TODO: Define outputs that will be consumed by other components

# Resource Group
output "resource_group_name" {
  description = "Nombre del grupo de recursos"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Región del grupo de recursos"
  value       = azurerm_resource_group.main.location
}



# AKS Cluster
output "aks_cluster_name" {
  description = "Nombre del clúster AKS"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_id" {
  description = "ID del clúster AKS"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_kubeconfig" {
  description = "Kubeconfig para el clúster AKS"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "aks_cluster_identity" {
  description = "Identidad gestionada del clúster AKS"
  value = {
    type         = azurerm_kubernetes_cluster.main.identity[0].type
    principal_id = azurerm_kubernetes_cluster.main.identity[0].principal_id
    tenant_id    = azurerm_kubernetes_cluster.main.identity[0].tenant_id
  }
}



# Azure Container Registry
output "acr_name" {
  description = "Nombre del Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "URL del servidor de login de ACR"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_id" {
  description = "ID del Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}



# Azure Key Vault
output "key_vault_name" {
  description = "Nombre del Azure Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI del Azure Key Vault"
  value       = azurerm_key_vault.main.vault_uri
  sensitive   = true
}

output "key_vault_id" {
  description = "ID del Azure Key Vault"
  value       = azurerm_key_vault.main.id
}



# PostgreSQL Database
output "postgres_server_name" {
  description = "Nombre del servidor PostgreSQL"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgres_fqdn" {
  description = "FQDN del servidor PostgreSQL"
  value       = azurerm_postgresql_flexible_server.main.fqdn
  sensitive   = true
}



# Networking
output "vnet_name" {
  description = "Nombre de la red virtual"
  value       = azurerm_virtual_network.main.name
}

output "vnet_id" {
  description = "ID de la red virtual"
  value       = azurerm_virtual_network.main.id
}

output "aks_subnet_id" {
  description = "ID de la subred AKS"
  value       = azurerm_subnet.aks.id
}

# AKS Node Resource Group
output "aks_node_resource_group" {
  description = "Resource Group gestionado de nodos AKS"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

# IP pública para Services LoadBalancer en AKS
output "aks_lb_public_ip_address" {
  description = "Dirección IP pública estática para Services tipo LoadBalancer"
  value       = azurerm_public_ip.aks_lb.ip_address
}

# Application Gateway
output "application_gateway_name" {
  description = "Nombre del Application Gateway"
  value       = azurerm_application_gateway.main.name
}

output "application_gateway_public_ip" {
  description = "IP pública del Application Gateway"
  value       = azurerm_public_ip.appgw.ip_address
}

# Monitoring
output "log_analytics_workspace_id" {
  description = "ID del Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "application_insights_connection_string" {
  description = "Cadena de conexión para Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Clave para Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

# Configuración GitHub Actions OIDC
output "github_actions_client_id" {
  description = "Client ID para GitHub Actions (AZURE_CLIENT_ID)"
  value       = azuread_application.github_actions.client_id
}

output "github_actions_tenant_id" {
  description = "Tenant ID para GitHub Actions (AZURE_TENANT_ID)"
  value       = data.azuread_client_config.current.tenant_id
}

output "github_actions_subscription_id" {
  description = "Subscription ID para GitHub Actions (AZURE_SUBSCRIPTION_ID)"
  value       = var.subscription_id
  sensitive   = true
}
