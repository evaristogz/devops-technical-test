# DevOps Technical Test - Evaristo GZ

<p align="left">
  <!-- Estado de CI/CD GitHub Actions -->
  <a href="https://github.com/evaristogz/devops-technical-test/actions">
    <img src="https://github.com/evaristogz/devops-technical-test/actions/workflows/cicd.yml/badge.svg" alt="CI Status" />
  </a>
  <!-- Último tag frontend (GHCR) -->
  <a href="https://github.com/orgs/Fundacion-Cibervoluntarios/packages/container/ecommerce-frontend">
    <img src="https://img.shields.io/badge/dynamic/json?label=frontend%20latest&query=%24[0].name&url=https://ghcr.io/v2/fundacion-cibervoluntarios/ecommerce-frontend/tags/list" alt="Frontend latest tag" />
  </a>
  <!-- Último tag backend (GHCR) -->
  <a href="https://github.com/orgs/Fundacion-Cibervoluntarios/packages/container/ecommerce-backend">
    <img src="https://img.shields.io/badge/dynamic/json?label=backend%20latest&query=%24[0].name&url=https://ghcr.io/v2/fundacion-cibervoluntarios/ecommerce-backend/tags/list" alt="Backend latest tag" />
  </a>
  <!-- Terraform -->
  <a href="https://www.terraform.io/">
    <img src="https://img.shields.io/badge/Terraform-1.0%2B-623CE4?logo=terraform" alt="Terraform" />
  </a>
  <!-- Helm -->
  <a href="https://helm.sh/">
    <img src="https://img.shields.io/badge/Helm-3.12%2B-0F1689?logo=helm" alt="Helm" />
  </a>
  <!-- Kubernetes -->
  <a href="https://kubernetes.io/">
    <img src="https://img.shields.io/badge/Kubernetes-1.28%2B-326CE5?logo=kubernetes" alt="Kubernetes" />
  </a>
  <!-- Docker -->
  <a href="https://www.docker.com/">
    <img src="https://img.shields.io/badge/Docker-20.10%2B-2496ED?logo=docker" alt="Docker" />
  </a>
  <!-- Azure -->
  <a href="https://azure.microsoft.com/">
    <img src="https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoft-azure" alt="Azure" />
  </a>
</p>

> **Documento principal de la solución.** Para detalles específicos revisa los README de cada directorio: [infrastructure](infrastructure/README.md), [k8s-manifests](k8s-manifests/README.md), [helm-chart](helm-chart/README.md) y [src](src/README.MD).

> **[Ver enunciado o README.md original](README_original.MD)**

---

## Tabla de contenidos

1. [Resumen ejecutivo](#resumen-ejecutivo)
2. [Arquitectura de alto nivel](#arquitectura-de-alto-nivel)
3. [Estructura del repositorio](#estructura-del-repositorio)
4. [Prerrequisitos locales](#prerrequisitos-locales)
5. [Ejecución local rápida](#ejecución-local-rápida)
6. [Infraestructura con Terraform](#infraestructura-con-terraform)
7. [Despliegue en Kubernetes (manifests)](#despliegue-en-kubernetes-manifests)
8. [Helm chart](#helm-chart)
9. [CI/CD y validaciones](#cicd-y-validaciones)
10. [Variables, secretos y credenciales](#variables-secretos-y-credenciales)
11. [Troubleshooting](#troubleshooting)
12. [Enlaces útiles](#enlaces-útiles)

---

## Resumen ejecutivo

La solución despliega una aplicación de e-commerce compuesta por frontend React, backend Node.js, base de datos PostgreSQL y caché Redis sobre Azure. La infraestructura se define con Terraform, el despliegue en AKS se puede realizar con manifiestos crudos o mediante un chart de Helm, y la automatización se apoya en scripts de validación y pipelines de CI/CD.

---

## Arquitectura de alto nivel

- **Frontend**: React SPA servida por nginx (puerto 3000).
- **Backend**: API Node.js/Express (puerto 8080) con endpoints de health y readiness.
- **Base de datos**: Azure Database for PostgreSQL Flexible Server.
- **Cache**: Redis con persistencia (Azure Disk en AKS).
- **Networking**: AKS en VNet con subredes dedicadas; Application Gateway como entrada.
- **Seguridad**: Azure Key Vault para secretos, Azure Workload Identity, NetworkPolicies y Pod Security Standards.

---

## Estructura del repositorio

```
devops-technical-test/
├── README.md                 # Este archivo
├── README_original.MD        # Enunciado original de la prueba
├── infrastructure/           # Terraform para Azure
├── k8s-manifests/            # Manifiestos Kubernetes organizados por componente
├── helm-chart/               # Chart Helm parametrizable
├── src/                      # Código de la aplicación (frontend y backend)
└── scripts/                  # Scripts de validación
```

---

## Prerrequisitos locales

Instala y verifica versiones mínimas:

```bash
terraform version   # >= 1.0
az version          # >= 2.50
kubectl version     # >= 1.28
helm version        # >= 3.12
docker version      # >= 20.10
```

Herramientas opcionales: `tfsec`, `kubeval`, `actionlint`.

---


## Infraestructura con Terraform

- Ubicación: `infrastructure/`
- Define Resource Group, VNet/subredes, AKS (system y user node pools), ACR, PostgreSQL, Key Vault, Application Gateway, Log Analytics.
- Variables en `variables.tf` (valores de ejemplo en `terraform.tfvars.example`).
- Flujo recomendado:
  1. `cd infrastructure`
  2. `terraform init`
  3. `terraform plan -out tfplan`
  4. `terraform apply tfplan`
  5. Crear recursos Service Principal en Azure.

Outputs clave: nombre del ACR, kubeconfig, endpoint de base de datos, IP del Application Gateway.

---

## Despliegue con Terraform + Helm

1. Despliega la infraestructura:
  ```bash
  cd infrastructure
  terraform init
  terraform apply -auto-approve
  ```
  Espera a que termine y toma nota de la IP pública del Application Gateway (output `application_gateway_public_ip`).

2. Conéctate al clúster de Kubernetes de Azure (AKS)
Desde la raíz del repositorio haz:
  ```bash
   RG=$(terraform -chdir=infrastructure output -raw resource_group_name)
   CLUSTER=$(terraform -chdir=infrastructure output -raw aks_cluster_name)
   az aks get-credentials -g "$RG" -n "$CLUSTER" --overwrite-existing
  ```

3. Comprueba el estado del clúster en AKS:
  ```bash
   kubectl cluster-info
   kubectl get nodes -o wide
   kubectl get pods -A
   # Comprobación de readiness detallada (salud del API server y componentes):
   kubectl get --raw='/readyz?verbose'
  ```

4. Comprueba el servicio frontend:
  ```bash
   kubectl get svc -n ecommerce-app
   # frontend-service debe tener EXTERNAL-IP = 10.0.1.100
  ```

5. Extrae la dirección IP pública del AGW de AKS:
  ```bash
   az network public-ip list --resource-group rg-ecommerce-dev --query "[].{name:name, ip:ipAddress}" -o table
  ```

6. Crea, manualmente, el Service Principal con rol Contributor
  ```bash
   az ad sp create-for-rbac \
   --name "github-actions-sp" \
   --role "Contributor" \
   --scopes /subscriptions/$SUBSCRIPTION_ID
  ```

7. Extrae el ID del Service Principal y asigna el rol Network Contributor al SP
  ```bash
   SP_ID=$(az ad sp list --display-name "github-actions-sp" --query "[0].id" -o tsv)
   SUBSCRIPTION_ID=$(az account show --query id -o tsv)
   RG_NAME="rg-ecommerce-dev"
   VNET_NAME="vnet-ecommerce-dev"

   az role assignment create \
     --assignee "$SP_ID" \
     --role "Network Contributor" \
     --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}/providers/Microsoft.Network/virtualNetworks/${VNET_NAME}"
  ```

8. Accede a la app vía Application Gateway:
  ```bash
  curl http://<IP_PUBLICA_AGW>/
  # O abre en navegador: http://<IP_PUBLICA_AGW>/
  ```



---

### Notas importantes
- El Application Gateway enruta el tráfico externo a la IP interna del frontend-service (Internal Load Balancer).
- El Ingress de Kubernetes (manifiesto o Helm) debe estar presente para que AGIC configure el AGW.
- No se expone ninguna IP pública de tipo LoadBalancer en AKS, solo la del AGW.

---

## Variables, secretos y credenciales

- **Terraform**: usa `terraform.tfvars` o variables de entorno `TF_VAR_` para valores sensibles (por ejemplo, contraseñas DB).
- **Kubernetes**: secretos gestionados vía Key Vault + CSI (recomendado) o `secret.yaml` solo para desarrollo.
- **Contenedores**: imágenes en ACR (`<acr>.azurecr.io/ecommerce-frontend` y `ecommerce-backend`).
- **Autenticación**: preferir OIDC con GitHub Actions y Azure Workload Identity para acceso a Key Vault y ACR.

---

## Troubleshooting

- **Terraform**: si falla `plan`, revisa credenciales Azure (`az account show`) y versiones de provider.
- **kubectl dry-run**: ejecuta `kubectl apply -f k8s-manifests/ --dry-run=server` para detectar errores de esquema.
- **Helm lint**: `helm lint ./helm-chart -f helm-chart/values-dev.yaml`.
- **Imágenes**: valida acceso a ACR con `az acr login --name <ACR_NAME>` y `az acr repository list`.
- **Health checks**: `curl http://<LB_IP>:8080/health` y `curl http://<LB_IP>:3000/health`.
