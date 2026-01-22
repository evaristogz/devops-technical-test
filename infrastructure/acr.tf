# Azure Container Registry (ACR) y autenticación para AKS

# Data source para obtener el ACR existente
data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
}

# Habilitar admin user en ACR existente a través Azure CLI
# Se usa así por simplificar un poco el escenario
# Alternativa más segura: usar Managed Identity con rol AcrPull asignado al kubelet de AKS
resource "null_resource" "enable_acr_admin" {
  triggers = {
    acr_id = data.azurerm_container_registry.acr.id
  }

  provisioner "local-exec" {
    command = "az acr update --name ${var.acr_name} --resource-group ${var.resource_group_name} --admin-enabled true"
  }
}

# Crear imagePullSecret en Kubernetes con credenciales de ACR admin
# Este secret permite a los pods descargar imágenes del ACR privado
resource "null_resource" "create_acr_secret" {
  depends_on = [null_resource.enable_acr_admin]

  triggers = {
    namespace = var.kubernetes_namespace
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Obtener credenciales de ACR
      ACR_USERNAME=$(az acr credential show --name ${var.acr_name} --query username -o tsv)
      ACR_PASSWORD=$(az acr credential show --name ${var.acr_name} --query passwords[0].value -o tsv)
      
      # Crear o actualizar secret en Kubernetes
      kubectl create secret docker-registry acr-secret \
        --docker-server=${data.azurerm_container_registry.acr.login_server} \
        --docker-username=$ACR_USERNAME \
        --docker-password=$ACR_PASSWORD \
        --docker-email=null@evaristogz.com \
        --namespace=${var.kubernetes_namespace} \
        --dry-run=client -o yaml | kubectl apply -f -
    EOT
  }
}