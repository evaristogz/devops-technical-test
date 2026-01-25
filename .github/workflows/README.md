# GitHub Actions workflows - E-commerce application

> **[Volver al README.md principal del repositorio](../../README.MD)**

## Descripción

Este directorio contiene los **workflows de GitHub Actions** que orquestan el pipeline de **integración continua y despliegue continuo (CI/CD)** para la aplicación de e-commerce. Los workflows automatizan la validación, construcción, testeo, escaneo de seguridad y despliegue de la aplicación en Azure Kubernetes Service (AKS).

---

## Tabla de contenidos

1. [Estructura del directorio](#estructura-del-directorio)
2. [Descripción de workflows](#descripción-de-workflows)
3. [Requisitos previos](#requisitos-previos)
4. [Configuración de secrets y variables](#configuración-de-secrets-y-variables)
5. [Pipeline CI/CD](#pipeline-cicd)
6. [Triggers del pipeline](#triggers-del-pipeline)
7. [Jobs del pipeline](#jobs-del-pipeline)
8. [Ejecución manual](#ejecución-manual)
9. [Monitoreo y debugging](#monitoreo-y-debugging)
10. [Troubleshooting](#troubleshooting)
11. [Enlaces útiles](#enlaces-útiles)

---

## Estructura del directorio

```
.github/workflows/
├── cicd.yml               # Pipeline completo de CI/CD
├── dependabot.yml         # Configuración de Dependabot (actualizaciones automáticas)
└── README.md              # Este archivo
```

---

## Descripción de workflows

### cicd.yml

Pipeline completo de integración continua y despliegue continuo que orquesta todo el flujo desde la validación del código hasta el despliegue en Azure.

#### Características principales

- **Validación Infrastructure as Code (IaC)**: Terraform validation y plan
- **Build y Test**: Construcción de imágenes Docker y ejecución de tests
- **Seguridad**: Escaneo de vulnerabilidades con Trivy y tfsec
- **Validación Kubernetes**: Validación de manifests con kubeval y kube-score
- **Validación Helm**: Lint y template validation del chart
- **Despliegue**: Despliegue automático a development usando Helm
- **Reportes**: Generación de reports en GitHub Step Summary

#### Ambientes soportados

- **Development** (solucion-evaristogz): Despliegue automático en cada push
- **Staging** (main): Pendiente de implementación
- **Production** (main): Pendiente de implementación

---

## Requisitos previos

### Acceso y permisos

- **Repositorio**: Acceso push para crear branches y PRs
- **GitHub**: Token de GITHUB_TOKEN (automático en actions)
- **Azure**: Service Principal con permisos en la suscripción
- **Terraform Cloud**: API token para gestionar estado

### Configuración en GitHub

```bash
# 1. Ir a Settings → Secrets and variables → Actions
# 2. Crear los siguientes secrets (ver siguiente sección)
```

### Herramientas requeridas

Las herramientas se instalan automáticamente en los runners:

- Terraform >= 1.6.0
- Helm >= 3.12
- kubectl >= 1.27
- Docker
- Node.js 18
- Azure CLI

---

## Configuración de secrets y variables

### Secrets (cifrados)

Ir a **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Origen | Tipo | Descripción |
|--------|--------|------|-------------|
| `AZURE_CLIENT_ID` | Service Principal (appId) | OAuth 2.0 | Client ID del Service Principal creado para autenticación OIDC con Azure |
| `AZURE_TENANT_ID` | Service Principal (tenant) | OAuth 2.0 | Tenant ID de Azure Active Directory del Service Principal |
| `AZURE_SUBSCRIPTION_ID` | Azure Portal | Identificador | ID de la suscripción Azure donde se despliegan los recursos |
| `TF_API_TOKEN` | Terraform Cloud | API Token | Token de autenticación para acceder al estado remoto de Terraform en Terraform Cloud |
| `GITHUB_TOKEN` | GitHub Actions (automático) | OAuth 2.0 | Token automático de GitHub para acceder a GHCR y recursos del repositorio. Puede sobrescribirse si es necesario |

#### Obtener valores de los secrets

```bash
# AZURE_CLIENT_ID y AZURE_TENANT_ID - Crear Service Principal
az ad sp create-for-rbac \
  --name "github-actions-sp" \
  --role "Contributor" \
  --scopes /subscriptions/<SUBSCRIPTION_ID>

# Salida incluye:
# "appId": "<AZURE_CLIENT_ID>"
# "tenant": "<AZURE_TENANT_ID>"

# AZURE_SUBSCRIPTION_ID
az account show --query id -o tsv

# TF_API_TOKEN - Crear en Terraform Cloud
# 1. Ir a https://app.terraform.io/app/settings/tokens
# 2. Click "Create an API token"
# 3. Copiar el token generado

# GITHUB_TOKEN - Automático (no requiere configuración manual)
# Si necesitas generar uno manualmente:
# 1. Ir a Settings → Developer settings → Personal access tokens → Tokens (classic)
# 2. Click "Generate new token (classic)"
# 3. Seleccionar scopes: repo, write:packages, delete:packages
```

#### Configurar OIDC en Azure

```bash
# Registrar GitHub como proveedor OIDC confiable
# Ver: https://docs.microsoft.com/en-us/azure/active-directory/workload-identities/workload-identity-federation-create-trust-github

GITHUB_ORG="evaristogz"
GITHUB_REPO="devops-technical-test"

az ad app federated-credential create \
  --id $(az ad sp list --display-name github-actions-sp -o tsv --query [0].id) \
  --parameters '{
    "name": "github-${GITHUB_REPO}",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'"${GITHUB_ORG}/${GITHUB_REPO}"':ref:refs/heads/*",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Variables (públicas)

Ir a **Settings → Secrets and variables → Actions → New repository variable**

| Variable | Valor actual | Origen | Descripción |
|----------|--------------|--------|-------------|
| `AZURE_CONTAINER_REGISTRY` | `acrecommerceegz1992.azurecr.io` | Terraform output: `acr_login_server` | URL de login del Azure Container Registry para push de imágenes Docker |
| `AKS_CLUSTER_NAME` | `aks-ecommerce-dev` | Terraform output: `aks_cluster_name` | Nombre del cluster Azure Kubernetes Service donde se despliega la aplicación |
| `AKS_RESOURCE_GROUP` | `rg-ecommerce-dev` | Terraform output: `resource_group_name` | Nombre del Azure Resource Group que contiene los recursos |
| `HELM_CHART_PATH` | `helm-chart` | Path local en el repositorio | Ruta relativa al directorio del Helm chart (desde raíz del repositorio) |

#### Obtener valores desde Terraform

```bash
# Leer los outputs de Terraform para obtener los valores exactos
cd infrastructure

# AZURE_CONTAINER_REGISTRY
terraform output -raw acr_login_server

# AKS_CLUSTER_NAME
terraform output -raw aks_cluster_name

# AKS_RESOURCE_GROUP
terraform output -raw resource_group_name

# HELM_CHART_PATH (es fijo en el repositorio)
echo "helm-chart"
```

#### Script para configurar todas las variables

```bash
#!/bin/bash
set -e

# Ir al directorio infrastructure
cd infrastructure

echo "Extrayendo valores de Terraform..."

# Obtener los valores
ACR=$(terraform output -raw acr_login_server)
AKS_CLUSTER=$(terraform output -raw aks_cluster_name)
AKS_RG=$(terraform output -raw resource_group_name)
HELM_PATH="helm-chart"

# Mostrar los valores para configurar en GitHub
echo ""
echo "=== Valores para configurar en GitHub ==="
echo "AZURE_CONTAINER_REGISTRY=${ACR}"
echo "AKS_CLUSTER_NAME=${AKS_CLUSTER}"
echo "AKS_RESOURCE_GROUP=${AKS_RG}"
echo "HELM_CHART_PATH=${HELM_PATH}"
echo ""
echo "Ir a: Settings → Secrets and variables → Actions → Repository variables"
echo "y agregar estas 4 variables"
```

---

## Pipeline CI/CD

### Flujo general

```
┌─────────────────────────────────────────────────────────────────┐
│                        TRIGGER EVENT                            │
│  (push, pull_request, workflow_dispatch)                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
   Job 1: Validate   Job 2: Build   Job 3: Build Images
   Infrastructure   & Test          & Push Docker
        │                │                │
        └────────────────┼────────────────┘
                         │
                    ┌────┴────┐
                    │         │
                    ▼         ▼
            Job 4: Security   Job 5: Validate K8s
            Scan (Trivy,      Manifests (kubeval,
            tfsec)            kube-score)
                    │         │
                    └────┬────┘
                         │
                         ▼
                   Job 6: Validate
                   Helm Chart
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
   Job 7: Deploy    Job 8: Deploy    Job 9: Deploy
   Development      Staging (TODO)    Production (TODO)
```

### Estados del pipeline

```
✅ Success    - Todos los jobs completaron correctamente
⚠️ Warning    - Jobs completados pero con warnings
❌ Failed     - Al menos un job falló
⏳ Running    - Pipeline en ejecución
⏹️ Cancelled  - Pipeline cancelado manualmente
```

---

## Triggers del pipeline

### Trigger 1: Push a rama

```yaml
on:
  push:
    branches: [main, solucion-evaristogz]
    paths-ignore:
      - 'docs/**'
      - '*.md'
```

**Cuándo se ejecuta:**
- Al hacer push a main o solucion-evaristogz
- Excluye cambios solo en docs/ o archivos .md

**Flujo:**
- push a solucion-evaristogz → Despliegue a development (Job 7)
- push a main → Sin despliegue automático (Jobs 1-6 solamente)

### Trigger 2: Pull Request

```yaml
on:
  pull_request:
    branches: [main]
```

**Cuándo se ejecuta:**
- Al abrir o actualizar un PR hacia main
- Solo Jobs 1-6 (validación y tests)
- No ejecuta despliegue (Job 7+)

**Flujo:**
- PR abierto → Valida infraestructura, code, imagenes, seguridad, k8s, helm
- Los resultados se comentan en el PR

### Trigger 3: Manual (workflow_dispatch)

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options:
        - dev
        - staging
        - prod
```

**Cuándo se ejecuta:**
- Manualmente desde GitHub UI
- Requiere seleccionar ambiente (dev/staging/prod)

**Flujo:**
- Permite ejecutar pipeline manualmente en cualquier momento
- Útil para debugging o despliegues fuera de tiempo

---

## Jobs del pipeline

### Job 1: validate-infrastructure

Valida la configuración de Terraform y escanea seguridad.

**Pasos:**
1. Checkout del código
2. Setup Terraform
3. Azure login con OIDC
4. Terraform init, validate, plan
5. Escaneo de seguridad con tfsec
6. Comentario en PR con plan

**Duración:** ~3-5 minutos

**Salidas:**
- Plan de Terraform validado
- Reporte tfsec SARIF (Code scanning)
- Comentario en PR (si aplica)

```bash
# Ver detalles en GitHub Actions UI
# Settings → Actions → All workflows → Azure E-commerce CI/CD Pipeline
```

### Job 2: build-and-test

Construye la aplicación y ejecuta tests.

**Pasos:**
1. Checkout del código
2. Setup Node.js 18
3. Instalar dependencias (frontend + backend)
4. Linting (ESLint, etc.)
5. Tests unitarios con cobertura
6. Upload artifacts de cobertura

**Duración:** ~2-3 minutos

**Salidas:**
- Coverage reports (backend, frontend)
- Artifacts almacenados 30 días

**Nota:** Si no hay tests configurados, el job pasa sin error (continue-on-error: true)

### Job 3: build-images

Construye y publica imágenes Docker a GHCR y ACR.

**Pasos:**
1. Checkout del código
2. Azure login con OIDC
3. Login a GHCR y ACR
4. Asegurar imagen base Redis
5. Setup Docker Buildx
6. Build y push frontend image
7. Build y push backend image
8. Extract tags para Trivy
9. Resumen en GITHUB_STEP_SUMMARY

**Duración:** ~5-10 minutos

**Salidas:**
- Frontend image: `ghcr.io/<owner>/ecommerce-frontend:<tag>`
- Backend image: `ghcr.io/<owner>/ecommerce-backend:<tag>`
- ACR (si está disponible): `acr.../ecommerce-frontend:<tag>`
- Redis image: `ghcr.io/<owner>/redis:7-alpine`

**Tags generados:**
- `sha-<COMMIT_SHORT>` (tag de commit)
- `latest` (última versión)

### Job 4: security-scan

Escanea vulnerabilidades en imágenes Docker.

**Pasos:**
1. Checkout del código
2. Preparar referencias de imágenes para Trivy
3. Trivy scan frontend (formato SARIF)
4. Trivy scan backend (formato SARIF)
5. Upload SARIF results
6. Resumen en GITHUB_STEP_SUMMARY

**Duración:** ~3-5 minutos

**Salidas:**
- SARIF reports (Code scanning)
- Vulnerabilidades CRITICAL y HIGH detectadas
- Resultados en Security → Code scanning alerts

**Severidad scaneada:**
- CRITICAL
- HIGH

### Job 5: validate-k8s

Valida manifests Kubernetes con kubeval y kube-score.

**Pasos:**
1. Checkout del código
2. Install kubeval
3. Validar manifests con kubeval
4. Install kube-score
5. Análisis de seguridad con kube-score
6. Validar estructura de manifests
7. Upload validation reports

**Duración:** ~2-3 minutos

**Salidas:**
- kubeval-report.txt
- kube-score-report.txt
- Artifacts almacenados 30 días

**Recursos validados:**
- Deployments
- Services
- StatefulSets
- ConfigMaps
- Secrets
- HorizontalPodAutoscalers
- NetworkPolicies
- PDBs

### Job 6: validate-helm

Valida el Helm chart con lint y template validation.

**Pasos:**
1. Checkout del código
2. Setup Helm
3. Setup Terraform (para leer outputs)
4. Terraform init
5. Leer Terraform output (AKS LB Public IP)
6. Helm dependency update
7. Helm lint (default, dev, staging, prod)
8. Helm template validation (dry-run)
9. Validar templates con kubeval
10. Resumen en GITHUB_STEP_SUMMARY

**Duración:** ~3-4 minutos

**Salidas:**
- Helm lint report (todos los values files)
- Helm templates generadas (dev, staging, prod)
- Validación kubeval de templates
- Chart metadata y información

**Charts validados:**
- values.yaml (default)
- values-dev.yaml
- values-staging.yaml
- values-prod.yaml

### Job 7: deploy-dev

Despliegue automático a Development.

**Cuándo se ejecuta:**
- Solo si push es a rama `solucion-evaristogz`
- Después de completar Jobs 1-6 exitosamente

**Pasos:**
1. Checkout del código
2. Preparar configuración de imágenes
3. Azure login con OIDC
4. Obtener credenciales AKS
5. Setup Helm
6. Crear namespace ecommerce-app
7. Crear secret GHCR (imagePullSecret)
8. Limpiar releases fallidas (si existen)
9. Helm upgrade --install con values-dev.yaml
10. Esperar deployment (rollout status)
11. Obtener información del deployment
12. Resumen en GITHUB_STEP_SUMMARY

**Duración:** ~5-8 minutos

**Salidas:**
- Release Helm instalada/actualizada
- Deployments, Services, Pods en ejecución
- Summary con estado de deployment

**Configuración:**
- Namespace: ecommerce-app
- Chart path: helm-chart
- Values: values-dev.yaml
- Registry: ghcr.io/<owner>
- Image tag: sha-<COMMIT> o latest

### Job 8 & 9: deploy-staging y deploy-prod

Pendiente de implementar.

---

## Ejecución manual

### Ejecutar desde GitHub UI

```
1. Ir a Actions (en la página principal del repo)
2. Seleccionar "Azure E-commerce CI/CD Pipeline"
3. Click en "Run workflow"
4. Seleccionar rama: solucion-evaristogz
5. (Opcional) Ingresar inputs si está configurado workflow_dispatch
6. Click "Run workflow"
```

### Ejecutar via GitHub CLI

```bash
# Ver workflows disponibles
gh workflow list

# Ejecutar workflow específico
gh workflow run cicd.yml --ref solucion-evaristogz

# Ver ejecuciones
gh run list --workflow=cicd.yml

# Ver detalles de una ejecución
gh run view <RUN_ID> --log
```

### Ejecutar via curl (API)

```bash
# Trigger workflow_dispatch
curl -X POST https://api.github.com/repos/Fundacion-Cibervoluntarios/evaristogz-devops-technical-test/actions/workflows/cicd.yml/dispatches \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "ref": "solucion-evaristogz",
    "inputs": {
      "environment": "dev"
    }
  }'
```

---

## Monitoreo y debugging

### Ver logs del pipeline

```bash
# Opción 1: GitHub UI
# Actions → Azure E-commerce CI/CD Pipeline → Haz click en la ejecución
# Ver logs de cada job en el panel derecho

# Opción 2: GitHub CLI
gh run view <RUN_ID> --log

# Opción 3: GitHub CLI - Descargar logs completos
gh run download <RUN_ID> -D ./logs
```

### Entender failures

#### Job 1: validate-infrastructure

```bash
# Error típico: Terraform init falla
# Causa: TF_API_TOKEN inválido o expirado
# Solución: Regenerar token en Terraform Cloud y actualizar secret

# Error típico: Azure login falla
# Causa: AZURE_CLIENT_ID, AZURE_TENANT_ID o AZURE_SUBSCRIPTION_ID incorrectos
# Solución: Verificar secrets en GitHub Settings
```

#### Job 2: build-and-test

```bash
# Error típico: npm install falla
# Causa: package.json mal formado o dependencias conflictivas
# Solución: Ejecutar localmente "npm ci" para verificar

# Error típico: Tests fallan
# Causa: Tests no pasan en CI
# Solución: continue-on-error permite que el job pase
```

#### Job 3: build-images

```bash
# Error típico: ACR login falla
# Causa: Service Principal sin permisos en ACR
# Solución: Asignar role AcrPush al Service Principal
az role assignment create \
  --assignee <AZURE_CLIENT_ID> \
  --role AcrPush \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RG>/providers/Microsoft.ContainerRegistry/registries/<ACR_NAME>

# Error típico: Docker build falla
# Causa: Dockerfile incorrecto o contexto inválido
# Solución: Verificar dockerfile en src/frontend y src/backend
```

#### Job 7: deploy-dev

```bash
# Error típico: AKS credentials error
# Causa: Cluster no existe o Service Principal sin permisos
# Solución: Verificar variables AZURE_CONTAINER_REGISTRY, AKS_CLUSTER_NAME, AKS_RESOURCE_GROUP

# Error típico: Helm install timeout
# Causa: Pod no inicia dentro de 5 minutos
# Solución:
kubectl describe deployment ecommerce-frontend -n ecommerce-app
kubectl logs deployment/ecommerce-frontend -n ecommerce-app

# Error típico: ImagePullBackOff
# Causa: Secret GHCR mal configurado o imagen no existe
# Solución:
kubectl get secret ghcr-secret -n ecommerce-app -o yaml
kubectl describe pod <POD_NAME> -n ecommerce-app
```

---

## Troubleshooting

### Problema: Pipeline no se ejecuta en push

**Solución:**

```bash
# 1. Verificar que la rama está en el trigger
grep -A 5 "on:" .github/workflows/cicd.yml

# 2. Verificar que no hay paths-ignore que bloquean el cambio
grep -A 5 "paths-ignore:" .github/workflows/cicd.yml

# 3. Ejecutar manualmente
gh workflow run cicd.yml --ref solucion-evaristogz
```

### Problema: OIDC authentication falla

**Mensaje de error:** `OIDC token request failed`

**Solución:**

```bash
# 1. Verificar que el federated credential está creado
az ad app federated-credential list \
  --id $(az ad sp list --display-name github-actions-sp -o tsv --query [0].id)

# 2. Verificar que los secrets en GitHub son correctos
# Settings → Secrets and variables → Review AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID

# 3. Verificar permisos del Service Principal
az role assignment list --assignee <AZURE_CLIENT_ID>
```

### Problema: ACR unavailable

**Mensaje en logs:** `Skipping ACR copy (ACR login failed or ACR unavailable)`

**Información:** Es un warning, no un error. El pipeline continúa usando GHCR como fallback.

**Solución (si necesitas ACR):**

```bash
# 1. Verificar que ACR existe
az acr list --resource-group <RG_NAME>

# 2. Asignar permisos AcrPush
az role assignment create \
  --assignee <AZURE_CLIENT_ID> \
  --role AcrPush \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RG>/providers/Microsoft.ContainerRegistry/registries/<ACR_NAME>

# 3. Actualizar variable AZURE_CONTAINER_REGISTRY con nombre correcto
```

### Problema: Helm deploy timeout

**Mensaje de error:** `error waiting for deployment`

**Solución:**

```bash
# 1. Ver estado de los pods
kubectl get pods -n ecommerce-app -o wide

# 2. Describir el pod para ver eventos
kubectl describe pod <POD_NAME> -n ecommerce-app

# 3. Ver logs del pod
kubectl logs <POD_NAME> -n ecommerce-app

# Causas comunes:
# - ImagePullBackOff: Verificar credenciales de pull
# - CrashLoopBackOff: Verificar logs del container
# - Pending: Verificar recursos disponibles en el cluster
```

### Problema: LoadBalancer pending (sin IP externa)

**Mensaje de error:** `EXTERNAL-IP: <pending>` o `findMatchedPIPByLoadBalancerIP: cannot find public IP`

**Causa más común:** Límite de IPs públicas alcanzado en la suscripción/región

**Causa secundaria:** IP pública en otro resource group (AKS solo puede reutilizar IPs de su managed resource group)

**Diagnóstico:**

```bash
# 1. Ver eventos del servicio
kubectl describe svc ecommerce-frontend -n ecommerce-app

# 2. Buscar error específico
kubectl describe svc ecommerce-frontend -n ecommerce-app | grep -i "error\|warning" | head -20

# 3. Listar IPs públicas en el resource group principal
az network public-ip list --resource-group rg-ecommerce-dev \
  --query "[].{name:name, state:provisioningState, ip:ipAddress}"

# 4. Listar IPs en el managed resource group de AKS (donde AKS puede usarlas)
AKS_MC_RG=$(az aks show --resource-group rg-ecommerce-dev --name aks-ecommerce-dev \
  --query nodeResourceGroup -o tsv)
az network public-ip list --resource-group "$AKS_MC_RG" \
  --query "[].{name:name, state:provisioningState, ip:ipAddress}"
```

**Soluciones (en orden de recomendación):**

```bash
# Opción 1: Usar port-forward (recomendado para desarrollo)
kubectl port-forward svc/ecommerce-frontend 3000:3000 -n ecommerce-app
# Acceder en http://localhost:3000

# Opción 2: Cambiar a ClusterIP (sin LoadBalancer)
# Editar helm-chart/values-dev.yaml:
# frontend:
#   service:
#     type: ClusterIP
kubectl patch svc ecommerce-frontend -n ecommerce-app \
  -p '{"spec":{"type":"ClusterIP"}}'

# Opción 3: Usar Ingress/Application Gateway (producción)
# Configurar en values-dev.yaml con Application Gateway
# El tráfico va: Internet → Application Gateway (IP 20.166.62.7) → Ingress → Frontend ClusterIP

# Opción 4: Crear IP pública nueva en managed resource group de AKS (si necesitas LoadBalancer)
AKS_MC_RG=$(az aks show --resource-group rg-ecommerce-dev --name aks-ecommerce-dev \
  --query nodeResourceGroup -o tsv)

# Crear IP pública
az network public-ip create \
  --resource-group "$AKS_MC_RG" \
  --name pip-ecommerce-frontend \
  --sku Standard \
  --allocation-method Static

# Obtener la IP
FRONTEND_IP=$(az network public-ip show \
  --resource-group "$AKS_MC_RG" \
  --name pip-ecommerce-frontend \
  --query ipAddress -o tsv)

# Asignarla al servicio
kubectl patch svc ecommerce-frontend -n ecommerce-app \
  -p "{\"spec\":{\"loadBalancerIP\":\"$FRONTEND_IP\"}}"

# Verificar
kubectl get svc ecommerce-frontend -n ecommerce-app
```

### Problema: Cambios no se ven en desarrollo

**Verificación:**

```bash
# 1. Verificar que el deployment se actualizó
kubectl get deployment ecommerce-frontend -n ecommerce-app -o yaml

# 2. Ver historia de deployments
kubectl rollout history deployment/ecommerce-frontend -n ecommerce-app

# 3. Ver eventos
kubectl get events -n ecommerce-app --sort-by='.lastTimestamp'

# Solución: Hacer push de nuevo cambio o ejecutar manual workflow
```

---

## Enlaces útiles

### Documentación oficial

- **GitHub Actions**
  - [GitHub Actions Documentation](https://docs.github.com/en/actions)
  - [Workflow syntax reference](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
  - [Context and expression syntax](https://docs.github.com/en/actions/learn-github-actions/contexts)

- **GitHub Actions - Autenticación**
  - [OIDC token](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
  - [Azure Login Action](https://github.com/azure/login)

- **Herramientas de validación**
  - [Terraform Documentation](https://www.terraform.io/docs)
  - [tfsec - Security Scanner for Terraform](https://aquasecurity.github.io/tfsec/)
  - [Helm Documentation](https://helm.sh/docs/)
  - [kubeval - Kubernetes manifest validator](https://www.kubeval.com/)
  - [kube-score - Security checker for Kubernetes](https://github.com/zegl/kube-score)
  - [Trivy - Vulnerability Scanner](https://github.com/aquasecurity/trivy)

- **Docker**
  - [Docker build push action](https://github.com/docker/build-push-action)
  - [Docker metadata action](https://github.com/docker/metadata-action)

---
