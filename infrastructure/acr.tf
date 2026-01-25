# Azure Container Registry (ACR) y autenticación para AKS

# Nota: El usuario admin de ACR se gestiona directamente con
# `admin_enabled = var.acr_admin_enabled` en el recurso
# `azurerm_container_registry` definido en main.tf.
# En entornos de producción se recomienda dejarlo deshabilitado
# y otorgar el rol "AcrPull" a la identidad de kubelet de AKS
# para que los pods puedan extraer imágenes sin secretos.

# NOTA: Creación del imagePullSecret en Kubernetes
# 
# Esto debe hacerse manualmente después de habilitar el admin:
# 
# ACR_USERNAME=$(az acr credential show --name ${ACR_NAME} --query username -o tsv)
# ACR_PASSWORD=$(az acr credential show --name ${ACR_NAME} --query passwords[0].value -o tsv)
# kubectl create secret docker-registry acr-secret \
#   --docker-server=${ACR_NAME}.azurecr.io \
#   --docker-username=$ACR_USERNAME \
#   --docker-password=$ACR_PASSWORD \
#   --docker-email=noreply@example.com \
#   --namespace=ecommerce-app \
#   --dry-run=client -o yaml | kubectl apply -f -
#
# Alternativa más segura para producción:
# Asignar rol AcrPull al kubelet identity de AKS (no requiere admin user ni imagePullSecret)