# Terraform infrastructure - Azure e-commerce

> **[Volver al README.md principal del repositorio](../README.MD)** 

## Descripción

Este directorio contiene toda la configuración de **Terraform** necesaria para desplegar la infraestructura completa en Microsoft Azure. Incluye la creación de redes virtuales, AKS (Azure Kubernetes Service), bases de datos, contenedores y todos los servicios necesarios para ejecutar la aplicación de e-commerce de forma segura, escalable y resiliente.

---

## Tabla de contenidos

1. [Estructura del directorio](#estructura-del-directorio)
2. [Descripción de archivos](#descripción-de-archivos)
3. [Requisitos previos](#requisitos-previos)
4. [Variables de configuración](#variables-de-configuración)
5. [Componentes de infraestructura](#componentes-de-infraestructura)
6. [Guía de despliegue](#guía-de-despliegue)
7. [Acceso y gestión de AKS](#acceso-y-gestión-de-aks)
8. [Validación y testing](#validación-y-testing)
9. [State management](#state-management)
10. [Seguridad](#seguridad)
11. [Mantenimiento](#mantenimiento)
12. [Solución de problemas](#solución-de-problemas)
13. [Enlaces útiles](#enlaces-útiles)

---

## Estructura del directorio

```
infrastructure/
├── main.tf                     # Recurso principal (AKS, VNet, subnets, etc.)
├── variables.tf                # Definición de variables de entrada
├── outputs.tf                  # Outputs/exporta valores de recursos creados
├── locals.tf                   # Variables locales (computed values)
├── providers.tf                # Configuración de providers (azurerm, azuread, azapi)
├── versions.tf                 # Versiones de Terraform y providers
│
├── acr.tf                      # Azure Container Registry (ACR)
├── public-ip.tf                # Public IP para Application Gateway
├── data.tf                     # Data sources (búsqueda de datos existentes)
│
├── terraform.tfvars            # Valores específicos de variables (local development)
├── .terraform.lock.hcl         # Lock file de versiones (commit a git)
│
├── README.md                   # Este archivo
└── .terraform/                 # Cache local de modules y plugins (gitignored)
```

---

## Descripción de archivos

### Archivos principales

**main.tf** (531 líneas)
- Resource Group principal
- Virtual Network (VNet) con 3 subnets:
  - AKS subnet (10.0.1.0/24)
  - Database subnet (10.0.2.0/24)
  - Application Gateway subnet (10.0.3.0/24)
- Network Security Groups (NSG) con reglas de entrada/salida
- AKS cluster con node pools
- Azure Database for PostgreSQL Flexible Server
- Azure Files para almacenamiento
- Azure Key Vault para secrets
- Log Analytics Workspace
- Application Gateway

**variables.tf** (287 líneas)
- `subscription_id` - ID de suscripción Azure (sensible)
- `environment` - dev/staging/prod
- `location` - Región Azure (default: North Europe)
- `project_name` - Nombre proyecto (default: ecommerce)
- Variables para AKS, database, networking (a completar)
- Validaciones inline en las variables

**outputs.tf**
- AKS kubeconfig
- ACR login server
- Database connection string
- Application Gateway IP
- Key Vault ID
- Log Analytics Workspace ID

**locals.tf**
- `name_prefix` - Prefijo computed para nombres consistentes
- `common_tags` - Tags aplicados a todos los recursos
- Otros valores locales reutilizables

**providers.tf**
- Azure provider (azurerm) con features
- Azure AD provider (azuread)
- Azure API provider (azapi)
- Autenticación vía Azure CLI

**versions.tf**
- Terraform >= 1.0
- Versiones mínimas de providers

### Archivos específicos

**acr.tf** - Azure Container Registry
- Crear ACR para almacenar imágenes Docker
- Integración con AKS para pull de imágenes
- Configuración de autenticación

**public-ip.tf** - Public IP
- IP pública estática para Application Gateway
- SKU: Standard
- Allocation: Static

**data.tf** - Data sources
- Buscar datos de Azure ya existentes
- Current Azure context/subscription
- Kubernetes versions disponibles

### Archivos de configuración

**terraform.tfvars.example**
- Debe copiarse a terraform.tfvars
- Valores específicos por environment
- Números de nodos, tamaños VM, etc.
- NO committed a git en producción (usar .gitignore)

---

## Requisitos previos

### Herramientas locales

```bash
# Terraform >= 1.0
terraform version

# Azure CLI >= 2.50
az --version

# kubectl (para interactuar con AKS)
kubectl version --client

```

### Acceso a Azure

```bash
# Autenticarse en Azure
az login

# Verificar suscripción activa
az account show

# (Opcional) Cambiar suscripción
az account set --subscription <SUBSCRIPTION_ID>
```

---

## Variables de configuración

### Obligatorias

```hcl
subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### Con valores por defecto

| Variable | Default | Descripción |
|----------|---------|-------------|
| `environment` | dev | dev/staging/prod |
| `location` | North Europe | Región Azure |
| `project_name` | ecommerce | Nombre del proyecto |

### Variables a completar

#### AKS (Azure Kubernetes Service)

| Variable | Descripción | Valores posibles | Recomendado |
|----------|-------------|------------------|-------------|
| `aks_node_count` | Nodos iniciales en node pool usuario | 1-10 | 2 (dev), 3 (prod) |
| `aks_vm_size` | Tamaño VM nodos | Standard_B2s, Standard_D2s_v3, Standard_DS2_v2, Standard_D4s_v3 | Standard_DS2_v2 |
| `aks_auto_scaling` | Habilitar autoscaling horizontal | true, false | true |
| `aks_min_count` | Mínimo de nodos | 1-5 | 2 |
| `aks_max_count` | Máximo de nodos | 3-10 | 5 |
| `aks_os_disk_size_gb` | Tamaño disco SO | 30-1000 | 128 |
| `aks_kubernetes_version` | Versión K8s | 1.27, 1.28, 1.29, latest | latest |

#### Database (PostgreSQL)

| Variable | Descripción | Valores posibles | Recomendado |
|----------|-------------|------------------|-------------|
| `db_admin_username` | Usuario administrador | Alfanumérico (no postgres, azure_superuser) | dbadmin |
| `db_password` | Contraseña admin | Mín. 8 caracteres, números, letras, símbolos | (usar TF_VAR_) |
| `db_version` | Versión PostgreSQL | 11, 12, 13, 14, 15 | 14 |
| `db_sku` | SKU servidor | Standard_B1ms, Standard_B2s, Standard_D2s_v3 | Standard_B1ms (dev), Standard_D2s_v3 (prod) |
| `db_storage_mb` | Almacenamiento inicial | 32768-1048576 | 32768 (32GB) |
| `db_backup_retention_days` | Retención backups | 7-35 | 7 (dev), 35 (prod) |
| `db_geo_redundant_backup` | Backup geo-redundante | true, false | false (dev), true (prod) |
| `db_high_availability` | Alta disponibilidad | true, false | false (dev), true (prod) |

#### Networking

| Variable | Descripción | Valores posibles | Recomendado |
|----------|-------------|------------------|-------------|
| `vnet_address_space` | Rango CIDR VNet | CIDR válido | ["10.0.0.0/16"] |
| `aks_subnet_address_prefix` | CIDR subnet AKS | Dentro de VNet | "10.0.1.0/24" |
| `db_subnet_address_prefix` | CIDR subnet Database | Dentro de VNet | "10.0.2.0/24" |
| `agw_subnet_address_prefix` | CIDR subnet App Gateway | Dentro de VNet | "10.0.3.0/24" |
| `enable_network_policy` | Habilitar Network Policy | true, false | true |

#### Application Gateway

| Variable | Descripción | Valores posibles | Recomendado |
|----------|-------------|------------------|-------------|
| `agw_sku` | SKU Gateway | Standard, Standard_v2, WAF_v2 | WAF_v2 |
| `agw_capacity` | Instancias (v2) | 1-10 | 2 (dev), 3 (prod) |
| `agw_enable_waf` | Habilitar WAF | true, false | true |
| `agw_enable_http2` | Habilitar HTTP/2 | true, false | true |

#### Azure Container Registry

| Variable | Descripción | Valores posibles | Recomendado |
|----------|-------------|------------------|-------------|
| `acr_sku` | SKU registro | Basic, Standard, Premium | Standard (dev), Premium (prod) |
| `acr_admin_enabled` | Usuario admin | true, false | false (usar Workload Identity) |
| `acr_public_network_access` | Acceso red pública | true, false | true |

#### Key Vault & Storage

| Variable | Descripción | Valores posibles | Recomendado |
|----------|-------------|------------------|-------------|
| `keyvault_soft_delete_retention` | Retención soft delete | 7-90 | 30 |
| `keyvault_sku` | SKU | standard, premium | standard |
| `storage_account_tier` | Tier almacenamiento | Standard, Premium | Standard |
| `storage_account_replication` | Replicación | LRS, GRS, RAGRS | LRS (dev), GRS (prod) |

#### Tags y Metadatos

| Variable | Descripción | Valores posibles | Recomendado |
|----------|-------------|------------------|-------------|
| `environment` | Entorno | dev, staging, prod | dev |
| `location` | Región Azure | eastus, westeurope, northeurope, etc. | North Europe |
| `project_name` | Nombre proyecto | Alfanumérico, guiones | ecommerce |
| `cost_center` | Centro de costos | Alfanumérico | (según org) |
| `owner_email` | Email propietario | Email válido | (según org) |

---

## Componentes de infraestructura

### Resource Group
- Nombre: `rg-{project}-{environment}`
- Contiene todos los recursos
- Tags: environment, project, created_date

### Virtual Network
- CIDR: 10.0.0.0/16
- Subnets segmentadas por función
- Service endpoints para KeyVault

### Subnets
- **AKS** (10.0.1.0/24): Pods y nodos de K8s
- **Database** (10.0.2.0/24): PostgreSQL (aislada)
- **App Gateway** (10.0.3.0/24): Ingress controller

### Network Security Groups
- **AKS NSG**: 
  - Entrada desde App Gateway
  - Salida a Database (5432)
  - Salida a Container Registry
  - Salida a Key Vault

- **Database NSG**:
  - Entrada desde AKS subnet (5432)
  - Entrada desde propia subnet
  - Salida mínima necesaria

- **App Gateway NSG**:
  - Entrada HTTP/HTTPS (80, 443)
  - Entrada Management (65200-65535)
  - Salida a AKS

### AKS Cluster
- **System node pool**: 2 nodos (system)
- **User node pool**: 2-5 nodos (escalable)
- VM Size: Standard_DS2_v2 (recomendado)
- Network plugin: Azure CNI
- Network policy: enabled (para microsegmentación)
- Kubelet managed identity

### Azure Container Registry
- SKU: Premium (para geo-replication)
- Admin user: disabled (usar Workload Identity)
- Integración con AKS via role assignment

### Azure Database for PostgreSQL
- Version: 13+ (flexible server)
- SKU: Burstable (dev) / General (prod)
- High availability: Enabled (prod)
- Backup: 7 días (dev) / 35 días (prod)
- Delegación en subnet para seguridad

### Azure Key Vault
- SKU: Standard
- Soft delete: Enabled
- Purge protection: Enabled (prod)
- Acceso via Workload Identity
- Secrets para DB, app credentials

### Storage Account (Azure Files)
- Tier: Premium (NFS) o Standard
- Para uploads y archivos estáticos
- SMB shares para datos compartidos

### Application Gateway
- SKU: WAF_v2 (con Web Application Firewall)
- Capacity: Auto-scaling
- TLS termination: enabled
- SSL policy: modern
- Rules para enrutamiento a AKS

### Log Analytics Workspace
- Retention: 30 días (dev) / 90 días (prod)
- Integración con AKS para logs/métricas
- Application Insights para app telemétry

---

## Guía de despliegue

### Paso 1: Preparar entorno

```bash
# Clonar repositorio
git clone <REPO_URL>
cd infrastructure

# Autenticarse en Azure
az login
az account show

# Verificar Terraform
terraform version
```

#### Configurar backend de estado (en versions.tf)

**Nota**: La configuración de backend se gestiona en el archivo `versions.tf` dentro del bloque `terraform {}`. Terraform puede usar estado local (default), remoto en Azure Storage o Terraform Cloud. Elige según tu caso:

**Opción A: Estado local (solo desarrollo)**

En `versions.tf`, mantener comentados los bloques de `backend` y `cloud`:
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.00"
    }
    # ... otros providers
  }
  # Sin backend o cloud = estado local en terraform.tfstate
  # NO usar en producción compartido
}
```

**Opción B: Azure Storage (recomendado para producción)**

1. Crear Storage Account para tfstate:
```bash
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="tfstate$(date +%s | cut -c1-10)"
CONTAINER_NAME="tfstate"

az group create -n "$RESOURCE_GROUP" -l "North Europe"
az storage account create -n "$STORAGE_ACCOUNT" \
  -g "$RESOURCE_GROUP" \
  --sku Premium_LRS

az storage container create -n "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT"

echo "Storage Account: $STORAGE_ACCOUNT"
```

2. En `versions.tf`, descomentar y completar la sección de Azure Storage backend:
```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.00"
    }
    # ... otros providers
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateXXXXXXXX"  # Reemplazar
    container_name       = "tfstate"
    key                  = "ecommerce-app.tfstate"
  }
}
```

**Opción C: Terraform Cloud (alternativa, requiere cuenta)**

1. Crear cuenta en [https://app.terraform.io](https://app.terraform.io)
2. Generar API token: Settings → Tokens
3. Crear archivo `~/.terraformrc`:
```hcl
credentials "app.terraform.io" {
  token = "YOUR_API_TOKEN"
}
```

4. En `versions.tf`, descomentar/reemplazar con cloud:
```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.00"
    }
    # ... otros providers
  }

  cloud {
    organization = "YOUR_ORG"  # Tu organización
    
    workspaces {
      name = "ecommerce-dev"   # Nombre workspace
    }
  }
}
```

5. Configurar variables sensibles en Terraform Cloud:
   - `TF_VAR_subscription_id` (sensible)
   - `TF_VAR_db_password` (sensible)
   - Otras variables según necesidad

### Paso 2: Inicializar Terraform

```bash
# Descargar providers y modules
terraform init
```

**Nota**: Si cambias la configuración de backend en `versions.tf`, deberás ejecutar `terraform init` nuevamente. Terraform detectará el cambio y migrará el estado automáticamente si es necesario.

### Paso 3: Validar configuración

```bash
# Validar sintaxis
terraform validate

# Formatear código
terraform fmt -recursive

# Lint (si tfsec está instalado)
tfsec .
```

### Paso 4: Plan despliegue

```bash
# Ver cambios que se harán
terraform plan -out=tfplan

# Guardar plan para auditabilidad
terraform plan -out=tfplan-$(date +%s)
```

### Paso 5: Aplicar cambios

```bash
# Aplicar plan (requiere confirmación)
terraform apply tfplan

# O aplicar directamente (NO recomendado)
terraform apply -auto-approve

# Esperar 10-15 minutos para AKS
```

### Paso 6: Acceder al AKS creado

#### Obtener credenciales AKS

Después de que `terraform apply` finalice correctamente, el AKS está listo. Para acceder:

```bash
# Opción A: Usar outputs de Terraform (más fácil)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_NAME=$(terraform output -raw aks_cluster_name)

# Opción B: Usar valores conocidos
RESOURCE_GROUP="rg-ecommerce-dev"
AKS_NAME="aks-ecommerce-dev"

# Descargar kubeconfig y configurar kubectl
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME"

# Esto descarga el kubeconfig a ~/.kube/config automáticamente
```

#### Verificar acceso al AKS

```bash
# Verificar información del cluster
kubectl cluster-info

# Ver nodos del cluster
kubectl get nodes -o wide

# Ver pods en todos los namespaces
kubectl get pods -A

# Información detallada del cluster
kubectl describe cluster

# Ver contextos de kubectl
kubectl config get-contexts
```

#### Exportar kubeconfig a archivo

```bash
# Guardar kubeconfig en ubicación específica
az aks get-credentials \
  --resource-group "$RESOURCE_GROUP" \
  --name "$AKS_NAME" \
  --file kubeconfig-ecommerce.yaml

# Usar archivo específico
export KUBECONFIG=/ruta/al/kubeconfig-ecommerce.yaml
kubectl get nodes
```

#### Obtener información desde Terraform outputs

```bash
# Ver todos los outputs (incluyendo sensibles)
terraform output

# Ver outputs específicos sin valores sensibles
terraform output -raw aks_cluster_name
terraform output -raw resource_group_name

# Ver outputs en JSON
terraform output -json

# Valores sensibles (kubeconfig raw)
terraform output aks_kubeconfig | base64 -d > kubeconfig.yaml
```

#### Verificar acceso a servicios AKS

```bash
# Verificar acceso a Azure Container Registry
az acr list-runs --resource-group "$RESOURCE_GROUP"

# Verificar credenciales ACR
az acr credential show --resource-group "$RESOURCE_GROUP" --name "$(terraform output -raw acr_name)"

# Verificar Key Vault access (Workload Identity)
az keyvault secret list --vault-name "$(terraform output -raw key_vault_name)"

# Verificar credenciales de base de datos
az postgres flexible-server show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$(terraform output -raw postgres_server_name)"
```

#### Troubleshooting acceso AKS

```bash
# Error: "Unable to connect to the server"
# → Verificar firewall rules
az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" \
  --query "networkProfile.networkPolicy"

# Error: "Unauthorized"
# → Verificar RBAC y roles
kubectl auth can-i get pods --all-namespaces

# Error: "kubeconfig not found"
# → Recrear kubeconfig
az aks get-credentials --resource-group "$RESOURCE_GROUP" \
  --name "$AKS_NAME" --overwrite-existing

# Verificar autenticación actual
kubectl auth whoami
```

### Paso 7: Verificar infraestructura completa

```bash
# Ver todos los outputs principales
terraform output

# Información de recursos creados
az resource list --resource-group "$RESOURCE_GROUP" -o table

# Detalles específicos de AKS
az aks show --resource-group "$RESOURCE_GROUP" --name "$(terraform output -raw aks_cluster_name)" -o json | jq '.kubernetesVersion, .dnsPrefix, .networkProfile'

# Verificar AKS pods
kubectl get all -A

# Ver eventos del cluster
kubectl get events -A --sort-by='.lastTimestamp'
```

### Ejemplo completo (dev environment)

```bash
cd infrastructure

# 1. Init
terraform init

# 2. Validate
terraform validate
terraform fmt -recursive

# 3. Plan para dev
terraform plan \
  -var="environment=dev" \
  -var="project_name=ecommerce" \
  -var="subscription_id=$SUBSCRIPTION_ID" \
  -out=tfplan

# 4. Review plan
cat tfplan  # Revisar cambios

# 5. Aplicar
terraform apply tfplan
echo "Esperando 10-15 minutos a que AKS esté listo..."

# 6. Obtener outputs de Terraform
echo "=== Terraform Outputs ==="
terraform output -raw aks_cluster_name
terraform output -raw resource_group_name

# 7. Acceder al AKS
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_NAME=$(terraform output -raw aks_cluster_name)

echo "Descargando kubeconfig para $AKS_NAME..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME"

# 8. Verificar acceso
echo "=== Verificando acceso AKS ==="
kubectl cluster-info
kubectl get nodes -o wide
kubectl get all -A

# 9. Información de recursos
echo "=== Información de Infraestructura ==="
echo "ACR: $(terraform output -raw acr_login_server)"
echo "Key Vault: $(terraform output -raw key_vault_name)"
echo "PostgreSQL: $(terraform output -raw postgres_server_name)"
echo "PostgreSQL FQDN: $(terraform output -raw postgres_fqdn)"
echo "VNet: $(terraform output -raw vnet_name)"

# 10. Guardar kubeconfig en archivo
KUBECONFIG_FILE="kubeconfig-${AKS_NAME}.yaml"
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" \
  --file "$KUBECONFIG_FILE"
echo "Kubeconfig guardado en: $KUBECONFIG_FILE"
```

**Después de este proceso, tendrás:**
- ✅ AKS cluster operativo
- ✅ kubectl configurado y listo para usar
- ✅ Azure Container Registry accesible
- ✅ PostgreSQL database lista
- ✅ Key Vault con secretos
- ✅ Networking completamente configurado
- ✅ Próximo paso: Desplegar aplicación en k8s-manifests

---

## Validación y testing

### Linting y validación

```bash
# Validación sintaxis
terraform validate

# Formateo automático
terraform fmt -recursive

# Security scanning
tfsec .

# Compliance check (si está instalado)
terraform plan -json | jq '.resource_changes[] | select(.change.actions != null)'
```

### Cost estimation

```bash
# Estimar costo de recursos
terraform plan -json | infracost breakdown --path /dev/stdin

# O con tfcost
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan | tfcost
```

### Testing recursos

```bash
# Después de apply, verificar AKS
kubectl cluster-info

# Verificar nodos
kubectl get nodes -o wide

# Verificar storage classes
kubectl get sc

# Probar conectividad a database
kubectl run -it --rm \
  --image=mcr.microsoft.com/azure-cli:latest \
  --restart=Never \
  --namespace=kube-system \
  -- bash -c "psql -h <DB_HOSTNAME> -U postgres -c 'SELECT 1'"

# Verificar Key Vault access
az keyvault secret list --vault-name <VAULT_NAME>
```

---

## Acceso y gestión de AKS

Una vez que Terraform ha creado la infraestructura, el AKS está listo para recibir despliegues. Esta sección documenta cómo acceder y gestionar el cluster.

### Acceso inicial a AKS

#### Desde Terraform outputs

```bash
# 1. Obtener datos del cluster desde Terraform (desde el directorio infraestructure)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_NAME=$(terraform output -raw aks_cluster_name)
KUBECONFIG_RAW=$(terraform output aks_kubeconfig)

echo $RESOURCE_GROUP; echo $AKS_NAME, echo $KUBECONFIG_RAW

# 2. Configurar kubectl
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME"

# 3. Verificar conectividad
kubectl cluster-info
kubectl get nodes
```

#### Desde Azure CLI directamente

```bash
# Si conoces el nombre del resource group y AKS
az aks get-credentials --resource-group "rg-ecommerce-dev" --name "aks-ecommerce-dev"

# Listar todos los AKS en suscripción actual
az aks list -o table

# Obtener detalles de un AKS específico
az aks show --resource-group "rg-ecommerce-dev" --name "aks-ecommerce-dev"
```

#### Gestionar múltiples contextos

```bash
# Ver contextos disponibles
kubectl config get-contexts

# Cambiar contexto actual
kubectl config use-context <CONTEXT_NAME>

# Renombrar contexto
kubectl config rename-context old-name new-name

# Eliminar contexto
kubectl config delete-context context-to-remove

# Obtener contexto actual
kubectl config current-context
```

### Información del cluster

```bash
# Información general
kubectl cluster-info
kubectl version --short

# Nodos y recursos
kubectl get nodes -o wide
kubectl top nodes
kubectl describe nodes

# Namespaces
kubectl get namespaces
kubectl get ns

# Storage classes
kubectl get storageclass
kubectl get sc

# API resources disponibles
kubectl api-resources

# API versions
kubectl api-versions
```

### Verificar componentes creados por Terraform

```bash
# 1. Verificar Azure Container Registry (ACR)
ACR_NAME=$(terraform output -raw acr_name)
echo "ACR Login Server: $(terraform output -raw acr_login_server)"
az acr repository list --name "$ACR_NAME"

# 2. Verificar PostgreSQL Database
DB_NAME=$(terraform output -raw postgres_server_name)
DB_FQDN=$(terraform output -raw postgres_fqdn)
echo "PostgreSQL Server: $DB_FQDN"
az postgres flexible-server list --output table

# 3. Verificar Key Vault
KV_NAME=$(terraform output -raw key_vault_name)
KV_URI=$(terraform output -raw key_vault_uri)
echo "Key Vault: $KV_URI"
az keyvault secret list --vault-name "$KV_NAME" -o table

# 4. Verificar Virtual Network
VNET_NAME=$(terraform output -raw vnet_name)
echo "VNet: $VNET_NAME"
az network vnet list --output table

# 5. Verificar identidades manejadas
az identity list --query "[].name" -o table
```

### Conectar AKS con otros servicios

#### Verificar Workload Identity

```bash
# Listar todas las Service Accounts con Workload Identity configurada
kubectl get serviceaccount -A -o json | jq -r '.items[] | select(.metadata.annotations."azure.workload.identity/client-id") | "\(.metadata.namespace)/\(.metadata.name)"'

# Verificar anotaciones de un SA
kubectl describe sa <SA_NAME> -n <NAMESPACE>

# Probar acceso a Key Vault
kubectl run -it --rm secret-test \
  --image=mcr.microsoft.com/azure-cli:latest \
  --restart=Never \
  -- bash -c "az keyvault secret list --vault-name $(terraform output -raw key_vault_name)"
```

#### Verificar conectividad a PostgreSQL

```bash
# Desde un pod en el cluster
kubectl run -it --rm psql-test \
  --image=postgres:15 \
  --restart=Never \
  --env="PGHOST=$(terraform output -raw postgres_fqdn)" \
  --env="PGUSER=postgres" \
  -- psql -c "SELECT version();"

# O desde tu máquina local
DB_FQDN=$(terraform output -raw postgres_fqdn)
psql -h "$DB_FQDN" -U postgres -d postgres -c "SELECT 1;"
```

#### Verificar acceso a ACR

```bash
# Desde AKS usando Workload Identity
kubectl run -it --rm acr-test \
  --image=mcr.microsoft.com/azure-cli:latest \
  --restart=Never \
  -- bash -c "az acr login --name $(terraform output -raw acr_name)"

# Listar imágenes en ACR
az acr repository list --name "$(terraform output -raw acr_name)" --output table
```

### Monitoreo y logs del cluster

```bash
# Logs del control plane (si Azure Monitor está configurado)
az monitor diagnostic-settings create \
  --resource "$(terraform output -raw aks_cluster_id)" \
  --name "AKS-Diagnostics" \
  --workspace "$(terraform output -raw log_analytics_workspace_id)" \
  --logs '[{"category":"cluster-autoscaling","enabled":true}]'

# Eventos del cluster
kubectl get events -A --sort-by='.lastTimestamp'

# Logs de un pod específico
kubectl logs -f deployment/<DEPLOYMENT_NAME> -n <NAMESPACE>

# Describir un pod
kubectl describe pod <POD_NAME> -n <NAMESPACE>

# Status detallado del cluster
kubectl get componentstatuses
kubectl get cs
```

### Exportar y guardar kubeconfig

```bash
# Guardar kubeconfig en archivo específico
KUBECONFIG_FILE="./kubeconfig-prod.yaml"
az aks get-credentials \
  --resource-group "$(terraform output -raw resource_group_name)" \
  --name "$(terraform output -raw aks_cluster_name)" \
  --file "$KUBECONFIG_FILE"

# Usar archivo específico
export KUBECONFIG="$KUBECONFIG_FILE"
kubectl get nodes

# Combinar múltiples kubeconfigs
export KUBECONFIG="$HOME/.kube/config:$KUBECONFIG_FILE"
kubectl config get-contexts

# Guardar kubeconfig en Azure Key Vault
az keyvault secret set \
  --vault-name "$(terraform output -raw key_vault_name)" \
  --name "aks-kubeconfig" \
  --file "$KUBECONFIG_FILE"
```

### Acceso a AKS con RBAC

```bash
# Ver rol actual
kubectl auth can-i list pods --all-namespaces

# Ver permisos específicos
kubectl auth can-i get secrets -n kube-system
kubectl auth can-i create deployments -n default

# Ver quién soy
kubectl auth whoami
kubectl auth whoami -o json

# Ver ClusterRoles disponibles
kubectl get clusterrole
kubectl get clusterrolebinding

# Ver Roles por namespace
kubectl get role -A
kubectl get rolebinding -A
```

### Próximos pasos después de acceso a AKS

Una vez con acceso a AKS, puedes:

1. **Desplegar aplicación**: Ver [k8s-manifests/README.md](../k8s-manifests/README.md)
2. **Configurar Ingress**: Usar Application Gateway o Kubernetes Gateway API
3. **Instalar Helm charts**: Ver [helm-chart/README.md](../helm-chart/README.md)
4. **Configurar CI/CD**: Ver [.github/workflows/](../.github/workflows/)
5. **Monitoreo**: Configurar Azure Monitor o Prometheus + Grafana
6. **Seguridad**: Implementar Network Policies y Pod Security Standards

---

## State management

### Local state (development)

```bash
# Default en infraestructura/terraform.tfstate
# Solo para desarrollo local
# NUNCA commitear a git

# .gitignore debe incluir:
# terraform.tfstate
# terraform.tfstate.*
# .terraform/
# *.tfvars (si contiene valores sensibles)
```

### Remote state (producción)

```bash
# Usar Azure Storage como backend
# Crear cuenta storage para tfstate:

RESOURCE_GROUP="rg-tfstate"
STORAGE_ACCOUNT="tftstate$(date +%s)"
CONTAINER_NAME="tfstate"

az group create -n $RESOURCE_GROUP -l "North Europe"
az storage account create -n $STORAGE_ACCOUNT -g $RESOURCE_GROUP
az storage container create -n $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT

# Configurar backend en providers.tf:
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "<STORAGE_ACCOUNT>"
    container_name       = "tfstate"
    key                  = "prod.tfstate"
  }
}

# Luego: terraform init
```

### State locking

```bash
# Azure Storage maneja locking automáticamente
# Ver estado actual
terraform state show

# Listar recursos
terraform state list

# Ver estado de un recurso
terraform state show 'azurerm_kubernetes_cluster.main'
```

---

## Seguridad

### Mejores prácticas implementadas

- Secrets en Key Vault (no en tfvars)
- NSGs restrictivos (least privilege)
- Pod Security Standards en AKS
- Azure Workload Identity para acceso
- RBAC en AKS
- Network policies para microsegmentación
- Encriptación en tránsito (TLS)
- Subnet delegation para database

### Valores sensibles

```bash
# NO hardcodear en terraform.tfvars:
# - Contraseñas
# - API keys
# - Subscription IDs sensibles
# - Secretos

# Usar en su lugar:
# - Variables de entorno: TF_VAR_*
# - Azure Key Vault
# - Archivos .tfvars con .gitignore

# Ejemplo:
export TF_VAR_db_password="SuperSecurePassword!"
terraform apply
```

### Auditoría

```bash
# Ver historial de cambios
git log -- infrastructure/

# Ver diferencias tfstate
terraform state pull | jq . | less

# Audit logs en Azure
az monitor activity-log list --resource-group <RG_NAME>
```

---

## Mantenimiento

### Actualizaciones

```bash
# Actualizar providers
terraform init -upgrade

# Usar versiones específicas
terraform {
  required_version = ">= 1.0, < 2.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.50"
    }
  }
}
```

### Destrucción

```bash
# CUIDADO: Destruye TODOS los recursos

# Verificar qué será destruido
terraform plan -destroy

# Destruir (con confirmación)
terraform destroy

# Destruir sin confirmación (NO recomendado)
terraform destroy -auto-approve
```

### Backups

```bash
# Respaldar state
cp terraform.tfstate terraform.tfstate.backup

# Respaldar Azure (snapshots de discos)
az snapshot create \
  --resource-group <RG_NAME> \
  --source <DISK_ID> \
  --name "snapshot-$(date +%s)"
```

---

## Solución de problemas

### Error: "Invalid or expired Azure credentials"

```bash
# Re-autenticar
az login

# Verificar cuenta activa
az account show

# Verificar permisos
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

### Error: "AKS node pool creation failed"

```bash
# Revisar quota de vCPU
az vm list-usage --location "North Europe" -o table

# Aumentar quota
# https://docs.microsoft.com/en-us/azure/quotas/quickstart-increase-quota-portal
```

### Error: "Subnet address space conflicts"

```bash
# Verificar CIDR ranges:
# AKS:      10.0.1.0/24
# Database: 10.0.2.0/24
# Gateway:  10.0.3.0/24

# Cambiar en variables.tf si hay conflictos
terraform plan -var="aks_subnet_address_prefix=10.0.1.0/24"
```

### Error: "PostgreSQL admin username invalid"

```bash
# PostgreSQL no permite ciertos nombres:
# - postgres (reservado)
# - azure_superuser
# - azure_pg_admin

# Usar: dbadmin, postgres_admin, app_user

terraform plan -var="db_admin_username=dbadmin"
```

### Terraform plan tarda mucho

```bash
# Parallelizar operaciones
terraform apply -parallelism=10

# O verificar problemas de red
time terraform plan
```

---

## Enlaces útiles

### Documentación oficial

- **Terraform**
  - [Terraform Documentation](https://www.terraform.io/docs)
  - [Terraform Best Practices](https://www.terraform.io/docs/language/code-organization)
  - [Terraform Registry](https://registry.terraform.io/)

- **Azure Provider**
  - [AzureRM Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
  - [Azure Terraform Configuration Guide](https://learn.microsoft.com/en-us/azure/developer/terraform/)
  - [Terraform on Azure Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/manage/terraform/)

### Servicios Azure específicos

- [Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/)
- [Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/)
- [Azure Database for PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/)
- [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/)
- [Application Gateway](https://learn.microsoft.com/en-us/azure/application-gateway/)
- [Azure Virtual Network](https://learn.microsoft.com/en-us/azure/virtual-network/)
- [Network Security Groups](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)

### Herramientas y validación

- [tfsec - Terraform security scanner](https://github.com/aquasecurity/tfsec)
- [Infracost - Cost estimation](https://www.infracost.io/)
- [Terraform Cloud](https://app.terraform.io/) - Remote state y CI/CD
- [Pre-commit hooks para Terraform](https://github.com/antonbabenko/pre-commit-terraform)
- [TerraTest - Testing framework](https://terratest.gruntwork.io/)

### Azure CLI

- [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)
- [Azure CLI AKS commands](https://learn.microsoft.com/en-us/cli/azure/aks)
- [Azure CLI Container Registry commands](https://learn.microsoft.com/en-us/cli/azure/acr)

---

## Notas importantes

- **Subscription ID**: Cambiar por el ID real de tu suscripción Azure
- **Región**: North Europe por defecto, cambiar según región preferida
- **Costo**: Usar `terraform plan` con Infracost para estimar costos antes de aplicar
- **Timeouts**: AKS tarda 10-15 minutos en crearse, ser paciente
- **State file**: Nunca compartir `terraform.tfstate` sin encripción
- **Destructivo**: `terraform destroy` es irreversible, tener backups
- **Versionado**: Usar `.terraform.lock.hcl` para reproducibilidad
- **CI/CD**: Usar Terraform Cloud o Azure DevOps para deployments automáticos
- **Monitoreo**: Habilitar Application Insights para logs y métricas
- **Rollback**: Mantener backups de tfstate para rollback en caso de emergencia
