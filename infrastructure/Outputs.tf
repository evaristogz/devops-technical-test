# Output values for Azure E-commerce Infrastructure

# TODO: Define outputs that will be consumed by other components

# Resource Group
# output "resource_group_name" {
#   description = "Name of the main resource group"
#   value       = azurerm_resource_group.main.name
# }

# output "resource_group_location" {
#   description = "Location of the main resource group"
#   value       = azurerm_resource_group.main.location
# }

# AKS Cluster
# output "aks_cluster_name" {
#   description = "Name of the AKS cluster"
#   value       = azurerm_kubernetes_cluster.main.name
# }

# output "aks_cluster_id" {
#   description = "ID of the AKS cluster"
#   value       = azurerm_kubernetes_cluster.main.id
# }

# output "aks_kubeconfig" {
#   description = "Kubeconfig for the AKS cluster"
#   value       = azurerm_kubernetes_cluster.main.kube_config_raw
#   sensitive   = true
# }

# output "aks_cluster_identity" {
#   description = "Managed identity of the AKS cluster"
#   value = {
#     type         = azurerm_kubernetes_cluster.main.identity[0].type
#     principal_id = azurerm_kubernetes_cluster.main.identity[0].principal_id
#     tenant_id    = azurerm_kubernetes_cluster.main.identity[0].tenant_id
#   }
# }

# Azure Container Registry
# output "acr_name" {
#   description = "Name of the Azure Container Registry"
#   value       = azurerm_container_registry.main.name
# }

# output "acr_login_server" {
#   description = "Login server URL for ACR"
#   value       = azurerm_container_registry.main.login_server
# }

# output "acr_id" {
#   description = "ID of the Azure Container Registry"  
#   value       = azurerm_container_registry.main.id
# }

# Azure Key Vault
# output "key_vault_name" {
#   description = "Name of the Azure Key Vault"
#   value       = azurerm_key_vault.main.name
# }

# output "key_vault_uri" {
#   description = "URI of the Azure Key Vault"
#   value       = azurerm_key_vault.main.vault_uri
#   sensitive   = true
# }

# output "key_vault_id" {
#   description = "ID of the Azure Key Vault"
#   value       = azurerm_key_vault.main.id
# }

# PostgreSQL Database
# output "postgres_server_name" {
#   description = "Name of the PostgreSQL server"
#   value       = azurerm_postgresql_flexible_server.main.name
# }

# output "postgres_fqdn" {
#   description = "FQDN of the PostgreSQL server"
#   value       = azurerm_postgresql_flexible_server.main.fqdn
#   sensitive   = true
# }

# output "postgres_database_name" {
#   description = "Name of the PostgreSQL database"
#   value       = azurerm_postgresql_flexible_server_database.main.name
# }

# Networking
# output "vnet_name" {
#   description = "Name of the virtual network"
#   value       = azurerm_virtual_network.main.name
# }

# output "vnet_id" {
#   description = "ID of the virtual network"
#   value       = azurerm_virtual_network.main.id
# }

# output "aks_subnet_id" {
#   description = "ID of the AKS subnet"
#   value       = azurerm_subnet.aks.id
# }

# Application Gateway
# output "application_gateway_name" {
#   description = "Name of the Application Gateway"
#   value       = azurerm_application_gateway.main.name
# }

# output "application_gateway_public_ip" {
#   description = "Public IP of the Application Gateway"
#   value       = azurerm_public_ip.agw.ip_address
# }

# Monitoring
# output "log_analytics_workspace_id" {
#   description = "ID of the Log Analytics workspace"
#   value       = azurerm_log_analytics_workspace.main.id
# }

# output "application_insights_connection_string" {
#   description = "Connection string for Application Insights"
#   value       = azurerm_application_insights.main.connection_string
#   sensitive   = true
# }

# output "application_insights_instrumentation_key" {
#   description = "Instrumentation key for Application Insights"
#   value       = azurerm_application_insights.main.instrumentation_key
#   sensitive   = true
# }