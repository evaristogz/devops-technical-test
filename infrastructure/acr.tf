# Azure Container Registry (ACR) y autenticación para AKS

# Data source para obtener el ACR existente
data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
}

# Habilitar admin user en ACR existente usando azapi provider
# Esto actualiza el recurso existente sin necesidad de importarlo
resource "azapi_update_resource" "acr_enable_admin" {
  type        = "Microsoft.ContainerRegistry/registries@2023-07-01"
  resource_id = data.azurerm_container_registry.acr.id

  body = {
    properties = {
      adminUserEnabled = true
    }
  }
}

# NOTA: Creación del imagePullSecret en Kubernetes
# 
# Esto debe hacerse manualmente después de habilitar el admin:
# 
# ACR_USERNAME=$(az acr credential show --name acrecommercedevne01 --query username -o tsv)
# ACR_PASSWORD=$(az acr credential show --name acrecommercedevne01 --query passwords[0].value -o tsv)
# kubectl create secret docker-registry acr-secret \
#   --docker-server=acrecommercedevne01.azurecr.io \
#   --docker-username=$ACR_USERNAME \
#   --docker-password=$ACR_PASSWORD \
#   --docker-email=noreply@example.com \
#   --namespace=ecommerce-app \
#   --dry-run=client -o yaml | kubectl apply -f -
#
# Alternativa más segura para producción:
# Asignar rol AcrPull al kubelet identity de AKS (no requiere admin user ni imagePullSecret)