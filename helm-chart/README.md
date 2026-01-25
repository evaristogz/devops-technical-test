# Helm chart - E-commerce application

> **[Volver al README.md principal del repositorio](../README.MD)**

## Descripción

Este directorio contiene el **Helm chart** para desplegar la aplicación de e-commerce completa en Azure Kubernetes Service (AKS). El chart es parametrizable y soporta múltiples ambientes (dev, staging, prod) mediante valores específicos por entorno. Incluye todos los componentes: frontend React, backend Node.js, Redis cache, configuración, secretos y escalado automático.

---

## Tabla de contenidos

1. [Estructura del directorio](#estructura-del-directorio)
2. [Descripción de archivos](#descripción-de-archivos)
3. [Requisitos previos](#requisitos-previos)
4. [Verificar conexión a AKS](#verificar-conexión-a-aks)
5. [Estructura del chart](#estructura-del-chart)
6. [Configuración de valores](#configuración-de-valores)
7. [Instalación manual del chart](#instalación-manual-del-chart)
   - [Obtener dirección IP de acceso](#paso-7-obtener-dirección-ip-de-acceso-a-la-aplicación)
8. [Desinstalación manual del chart](#desinstalación-manual-del-chart)
9. [Validación y testing](#validación-y-testing)
10. [Actualización de releases](#actualización-de-releases)
11. [Rollback](#rollback)
12. [Solución de problemas](#solución-de-problemas)
13. [Enlaces útiles](#enlaces-útiles)

---

## Estructura del directorio

```
helm-chart/
├── Chart.yaml                 # Metadatos del chart (name, version, description)
├── values.yaml                # Valores default
├── values-dev.yaml            # Valores específicos para desarrollo
├── values-staging.yaml        # Valores específicos para staging
├── values-prod.yaml           # Valores específicos para producción
│
├── templates/                 # Plantillas Kubernetes
│   ├── _helpers.tpl          # Funciones y macros reutilizables
│   ├── configmap.yaml        # ConfigMap para configuración no sensible
│   ├── secret.yaml           # Secret para credenciales (desarrollo)
│   ├── serviceaccounts.yaml  # Service Accounts
│   │
│   ├── frontend-deployment.yaml  # Deployment frontend React
│   ├── frontend-service.yaml     # Service frontend
│   ├── frontend-hpa.yaml         # HorizontalPodAutoscaler frontend
│   │
│   ├── backend-deployment.yaml   # Deployment backend Node.js
│   ├── backend-service.yaml      # Service backend
│   ├── backend-hpa.yaml          # HorizontalPodAutoscaler backend
│   │
│   ├── redis-statefulset.yaml    # StatefulSet Redis
│   ├── redis-service.yaml        # Service Redis
│   │
│   └── (otros templates según sea necesario)
│
└── README.md                  # Este archivo
```

---

## Descripción de archivos

### Chart.yaml

Archivo de metadatos del Helm chart que contiene:
- **name**: `ecommerce-app`
- **version**: Versión del chart (semantic versioning)
- **appVersion**: Versión de la aplicación
- **description**: Descripción del chart
- **keywords**: Tags para búsqueda
- **home**: URL del repositorio
- **sources**: URLs de código fuente
- **maintainers**: Información de mantenedores

### Values files

**values.yaml** - Valores por defecto
```yaml
# Contiene configuración default para todos los servicios
# Variables para development
# Se sobrescribe con values-*.yaml según ambiente
```

**values-dev.yaml** - Configuración development
```yaml
# Menos réplicas
# Menos recursos
# Log verbose
# No secrets sensibles
```

**values-staging.yaml** - Configuración staging
```yaml
# Réplicas intermedias
# Recursos moderados
# Pruebas de carga
```

**values-prod.yaml** - Configuración producción
```yaml
# Máximo número de réplicas
# Máximos recursos
# Alta disponibilidad habilitada
# Secrets desde Azure Key Vault
```

### Templates

**_helpers.tpl** - Macros y funciones reutilizables
```
Contiene plantillas para:
- Nombres consistentes (fullname)
- Labels estándar
- Selectores
- Annotations
```

**configmap.yaml** - Configuración no sensible
```
Variables de entorno públicas:
- API URLs
- Ambiente
- Log levels
- Redis host/port
```

**secret.yaml** - Secrets (solo development, usar Key Vault en producción)
```
Credenciales sensibles:
- Database URL
- JWT secrets
- API keys
- Contraseñas
```

**serviceaccounts.yaml** - Identidades de pods
```
Service Accounts con:
- Labels
- Annotations (Azure Workload Identity)
```

**frontend-deployment.yaml** - Frontend React
```
3 réplicas, health checks, anti-affinity, HPA
```

**backend-deployment.yaml** - Backend Node.js
```
2-5 réplicas con autoscaling, conexión a DB/Redis
```

**redis-statefulset.yaml** - Redis con persistencia
```
StatefulSet con 1 réplica y PVC
```

---

## Requisitos previos

### Herramientas locales

```bash
# Helm >= 3.12
helm version

# kubectl configurado
kubectl version --client

# Acceso a AKS
kubectl cluster-info

# Azure CLI (opcional, para Key Vault)
az --version
```

### Acceso a AKS

Antes de instalar el chart, **DEBES estar conectado al AKS correcto**. Ver sección [Verificar conexión a AKS](#verificar-conexión-a-aks).

### Recursos en Azure (creados por Terraform)

- AKS cluster operativo
- Azure Container Registry (ACR)
- PostgreSQL Database
- Azure Key Vault
- Virtual Network configurada

---

## Verificar conexión a AKS

**IMPORTANTE**: Asegúrate de que estás usando el cluster AKS correcto antes de instalar.

### Paso 1: Verificar contexto actual

```bash
# Ver contexto actual
kubectl config current-context

# Ver todos los contextos disponibles
kubectl config get-contexts

# Cambiar a contexto correcto si es necesario
kubectl config use-context <CONTEXT_NAME>
```

### Paso 2: Verificar cluster correcto

```bash
# Información del cluster actual
kubectl cluster-info

# Servidor API del cluster
kubectl cluster-info | grep 'Kubernetes master'

# Verificar nodos
kubectl get nodes -o wide

# Verificar si es el cluster correcto
kubectl get nodes | grep -i aks  # Debe mostrar nodos AKS

# Ver región y detalles
kubectl describe nodes | grep -i azure
```

### Paso 3: Verificar namespace

```bash
# Ver namespace actual (default)
kubectl config view --minify | grep namespace

# Crear namespace si no existe
kubectl create namespace ecommerce-app

# Verificar namespace creado
kubectl get namespace ecommerce-app

# Cambiar namespace por defecto
kubectl config set-context --current --namespace=ecommerce-app
```

### Paso 4: Verificar ACR y base de datos

```bash
# Verificar acceso a ACR (desde la infraestructura Terraform)
ACR_NAME="<your-acr-name>"  # del output de Terraform
az acr login --name "$ACR_NAME"
az acr repository list --name "$ACR_NAME"

# Verificar conectividad a PostgreSQL
# (se hará durante la instalación del chart)
```

### Checklist pre-instalación

```bash
# Ejecutar todos estos comandos y verificar que funcionan:

# 1. Contexto correcto
kubectl config current-context | grep -i aks

# 2. Acceso al cluster
kubectl get nodes

# 3. Namespace existe
kubectl get namespace ecommerce-app

# 4. ACR accesible
az acr login --name "$(terraform output -raw acr_name)" 2>/dev/null

# 5. Helm disponible
helm version --short

echo "✓ Todas las verificaciones pasaron"
```

---

## Estructura del chart

### Convenciones de nombres

El chart usa convenciones consistentes para nombres de recursos:

```
{{ include "ecommerce-app.fullname" . }}

Resultado: ecommerce  (o valores personalizados)
```

### Labels estándar

Todos los recursos incluyen labels:

```yaml
app.kubernetes.io/name: ecommerce-app
app.kubernetes.io/instance: ecommerce (o custom)
app.kubernetes.io/version: 1.0.0
app.kubernetes.io/managed-by: Helm
component: frontend/backend/redis
```

### Selectores

Los services seleccionan pods usando:

```yaml
selector:
  app.kubernetes.io/name: ecommerce-app
  app.kubernetes.io/instance: ecommerce
  component: backend  # frontend/redis según el servicio
```

### Helper functions en _helpers.tpl

```hcl
{{ include "ecommerce-app.fullname" . }}     # Nombre completo
{{ include "ecommerce-app.labels" . }}        # Labels estándar
{{ include "ecommerce-app.selectorLabels" . }} # Selectores
```

---

## Configuración de valores

### Valores globales

```yaml
global:
  nameOverride: ""              # Sobrescribe el nombre del chart
  fullnameOverride: "ecommerce" # Nombre completo personalizado
  namespaceOverride: ""         # Namespace (default: ecommerce-app)
  version: v1.0.0               # Versión aplicación
  imageRegistry: acr.azurecr.io # Registry para imágenes
  imagePullSecrets:             # Secrets para pull de images
    - name: acr-secret
```

### Configuración de componentes

#### Frontend (React)

```yaml
frontend:
  enabled: true
  replicaCount: 3          # Número de réplicas
  
  image:
    repository: ecommerce-frontend  # Nombre imagen (sin registry)
    tag: latest                      # Tag imagen
    pullPolicy: Always               # Always/IfNotPresent/Never
  
  service:
    type: ClusterIP        # ClusterIP/LoadBalancer/NodePort
    port: 3000             # Puerto del servicio
  
  resources:
    requests:
      cpu: 100m            # CPU mínima
      memory: 128Mi         # Memoria mínima
    limits:
      cpu: 200m            # CPU máxima
      memory: 256Mi         # Memoria máxima
  
  autoscaling:
    enabled: true
    minReplicas: 3         # Mínimo replicas
    maxReplicas: 5         # Máximo replicas
    targetCPUUtilizationPercentage: 70
```

#### Backend (Node.js)

```yaml
backend:
  enabled: true
  replicaCount: 2
  
  image:
    repository: ecommerce-backend
    tag: latest
    pullPolicy: Always
  
  service:
    type: ClusterIP
    port: 8080
  
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
  
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 5
    targetCPUUtilizationPercentage: 70
```

#### Redis

```yaml
redis:
  enabled: true
  replicaCount: 1
  
  image:
    repository: redis
    tag: "7-alpine"
  
  storage:
    enabled: true
    size: 1Gi              # Tamaño PVC
    storageClassName: managed-premium
```

### Configuración por ambiente

#### Development (values-dev.yaml)

```yaml
# Menos recursos
frontend:
  replicaCount: 1
  resources:
    requests:
      cpu: 50m
      memory: 64Mi

backend:
  replicaCount: 1
  resources:
    requests:
      cpu: 100m
      memory: 128Mi

# Secrets locales (NO en producción)
secrets:
  enabled: true
  name: ecommerce-secrets-local
  databaseUrl: postgresql://user:pass@postgres:5432/db
```

#### Production (values-prod.yaml)

```yaml
# Máximos recursos y replicas
frontend:
  replicaCount: 3
  autoscaling:
    minReplicas: 3
    maxReplicas: 10

backend:
  replicaCount: 3
  autoscaling:
    minReplicas: 3
    maxReplicas: 10

# Usar Azure Key Vault para secrets
secrets:
  enabled: false  # No hardcodear secrets
  useKeyVault: true
```

---

## Instalación manual del chart

### Paso 1: Verificar prerequisites

```bash
# Usar el checklist anterior
kubectl config current-context
kubectl get nodes
kubectl get namespace ecommerce-app
helm version --short
```

### Paso 2: Validar el chart

```bash
cd helm-chart

# Validar sintaxis
helm lint .

# Validar con values específicos
helm lint -f values-dev.yaml .
helm lint -f values-prod.yaml .

# Ver qué recursos se crearían (dry-run)
helm template ecommerce . -f values-dev.yaml | head -100
```

### Paso 3: Instalar en development

```bash
cd helm-chart

# Instalación básica con valores dev
helm install ecommerce . \
  --namespace ecommerce-app \
  --create-namespace \
  -f values-dev.yaml

# Esperar a que los pods estén listos
kubectl rollout status deployment/ecommerce-frontend -n ecommerce-app
kubectl rollout status deployment/ecommerce-backend -n ecommerce-app

# Verificar instalación
helm status ecommerce -n ecommerce-app
kubectl get all -n ecommerce-app
```

### Paso 4: Instalar en production

```bash
cd helm-chart

# Instalación con valores producción
helm install ecommerce . \
  --namespace ecommerce-app \
  --create-namespace \
  -f values-prod.yaml \
  --values values-prod.yaml

# Con valores adicionales por línea de comando
helm install ecommerce . \
  --namespace ecommerce-app \
  --create-namespace \
  -f values-prod.yaml \
  --set frontend.replicaCount=5 \
  --set backend.replicaCount=5 \
  --set global.imageRegistry="myacr.azurecr.io"

# Ver valores desplegados
helm get values ecommerce -n ecommerce-app
```

### Paso 5: Verificar instalación

```bash
# Estado de la release
helm status ecommerce -n ecommerce-app

# Ver historia de despliegues
helm history ecommerce -n ecommerce-app

# Describir release
helm get manifest ecommerce -n ecommerce-app

# Todos los pods
kubectl get pods -n ecommerce-app -o wide

# Servicios
kubectl get svc -n ecommerce-app

# StatefulSets
kubectl get statefulset -n ecommerce-app

# Verif ación de logs
kubectl logs -f deployment/ecommerce-backend -n ecommerce-app --tail=50
```

### Paso 6: Verificar conectividad entre componentes

```bash
# Frontend → Backend
kubectl exec -it <FRONTEND_POD> -n ecommerce-app -- \
  curl http://ecommerce-backend:8080/health

# Backend → Redis
kubectl exec -it <BACKEND_POD> -n ecommerce-app -- \
  redis-cli -h ecommerce-redis ping

# Backend → PostgreSQL
kubectl exec -it <BACKEND_POD> -n ecommerce-app -- \
  psql -h <DB_HOSTNAME> -U postgres -c "SELECT 1;"
```

### Paso 7: Obtener dirección IP de acceso a la aplicación

La configuración implementada en los values (dev, staging, prod) utiliza **LoadBalancer** para exponer el frontend externamente.

#### Obtener la IP externa del LoadBalancer

```bash
# Ver estado del service frontend
kubectl get svc ecommerce-frontend -n ecommerce-app

# Esperar a que Azure asigne la IP externa (puede tardar minutos)
kubectl get svc ecommerce-frontend -n ecommerce-app -w

# Obtener la IP externa
FRONTEND_IP=$(kubectl get svc ecommerce-frontend -n ecommerce-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Acceso: http://$FRONTEND_IP:3000"
```

#### Verificar que la aplicación responde

```bash
# Desde la máquina local
FRONTEND_IP="<IP_OBTENIDA_ARRIBA>"
curl -v http://$FRONTEND_IP:3000

# O abrir directamente en navegador
# http://$FRONTEND_IP:3000
```

#### Script para obtener la dirección IP

```bash
#!/bin/bash
NAMESPACE="ecommerce-app"

echo "=== Obtener dirección IP del frontend ==="
echo

# Frontend service
echo "Estado del Service Frontend:"
kubectl get svc ecommerce-frontend -n "$NAMESPACE"
echo

# Esperar IP
echo "Obteniendo IP externa..."
for i in {1..60}; do
  FRONTEND_IP=$(kubectl get svc ecommerce-frontend -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  if [ -n "$FRONTEND_IP" ]; then
    echo "✓ IP obtenida: $FRONTEND_IP"
    echo "Acceder a: http://$FRONTEND_IP:3000"
    break
  fi
  echo "Esperando asignación de IP... ($i/60)"
  sleep 5
done

if [ -z "$FRONTEND_IP" ]; then
  echo "✗ No se asignó IP después de 5 minutos"
  echo "Verificar con: kubectl describe svc ecommerce-frontend -n $NAMESPACE"
fi
```

#### Solucionar problemas de acceso

```bash
# Si el LoadBalancer está pendiente de IP
kubectl describe svc ecommerce-frontend -n ecommerce-app

# Ver eventos
kubectl get events -n ecommerce-app --sort-by='.lastTimestamp'

# Verificar cuotas de IPs públicas en Azure
az network public-ip list --resource-group "$(terraform output -raw resource_group_name)"

# Si la aplicación está accesible pero no responde, verificar logs
kubectl logs deployment/ecommerce-frontend -n ecommerce-app
kubectl describe pod <FRONTEND_POD> -n ecommerce-app
```

---

## Desinstalación manual del chart

### Paso 1: Verificar release actual

```bash
# Ver releases instaladas
helm list -n ecommerce-app

# Verificar estado
helm status ecommerce -n ecommerce-app

# Ver qué recursos se eliminarán
helm get manifest ecommerce -n ecommerce-app
```

### Paso 2: Crear backup (recomendado)

```bash
# Hacer dump del estado actual
helm get values ecommerce -n ecommerce-app > ecommerce-values-backup.yaml
kubectl get all -n ecommerce-app -o yaml > ecommerce-resources-backup.yaml

# Backup de datos (si es necesario)
kubectl exec -it redis-0 -n ecommerce-app -- \
  redis-cli --rdb /backup/redis-dump.rdb
```

### Paso 3: Eliminar release

```bash
# Desinstalación normal (elimina recursos del chart)
helm uninstall ecommerce -n ecommerce-app

# Esperar a que se eliminen los pods
sleep 10
kubectl get pods -n ecommerce-app

# Verificar que se eliminó
helm list -n ecommerce-app  # No debe aparecer
```

### Paso 4: Limpiar namespace (opcional)

```bash
# Eliminar ConfigMaps y Secrets residuales
kubectl delete configmap -n ecommerce-app --all
kubectl delete secret -n ecommerce-app --all

# Eliminar namespace completo (borra todo)
kubectl delete namespace ecommerce-app

# Verificar
kubectl get namespace ecommerce-app  # Ya no debe existir
```

### Paso 5: Eliminar datos persistentes (si es necesario)

```bash
# CUIDADO: Esto es destructivo

# Listar PVCs
kubectl get pvc -n ecommerce-app

# Eliminar PVCs
kubectl delete pvc -n ecommerce-app --all

# Verificar discos en Azure
az disk list --resource-group <RG_NAME> -o table
```

### Testing de conectividad

```bash
# Pod a Pod
kubectl exec -it <POD_NAME> -n ecommerce-app -- bash

# Port-forward a servicios
kubectl port-forward svc/ecommerce-frontend 3000:3000 -n ecommerce-app
kubectl port-forward svc/ecommerce-backend 8080:8080 -n ecommerce-app

# Verificar DNS interno
kubectl run -it --rm debug \
  --image=busybox:1.28 \
  --restart=Never \
  -n ecommerce-app \
  -- sh -c "nslookup ecommerce-backend.ecommerce-app.svc.cluster.local"
```

---

## Actualización de releases

### Cambiar valores sin actualizar chart

```bash
# Actualizar valores existentes
helm upgrade ecommerce . \
  -f values-prod.yaml \
  --set frontend.replicaCount=5

# Verificar cambios
helm diff upgrade ecommerce . -f values-prod.yaml
helm get values ecommerce -n ecommerce-app
```

### Actualizar chart a nueva versión

```bash
# Cambiar version en Chart.yaml
# version: 0.2.0

# Actualizar release
helm upgrade ecommerce . \
  -f values-prod.yaml \
  --install  # Instala si no existe, actualiza si existe

# Ver historia de upgrades
helm history ecommerce -n ecommerce-app

# Ver cambios antes de aplicar
helm diff upgrade ecommerce .
```

### Rolling update con Helm

```bash
# Actualizar imagen
helm upgrade ecommerce . \
  -f values-prod.yaml \
  --set backend.image.tag=v1.0.1

# Verificar rollout
kubectl rollout status deployment/ecommerce-backend -n ecommerce-app

# Ver eventos
kubectl get events -n ecommerce-app --sort-by='.lastTimestamp'
```

---

## Rollback

### Rollback a versión anterior

```bash
# Ver historial
helm history ecommerce -n ecommerce-app

# Rollback a revisión anterior
helm rollback ecommerce -n ecommerce-app

# Rollback a revisión específica
helm rollback ecommerce 2 -n ecommerce-app

# Verificar rollback
helm status ecommerce -n ecommerce-app
kubectl get pods -n ecommerce-app
```

---

## Solución de problemas

### Error: "release not found"

```bash
# Ver releases instaladas
helm list -n ecommerce-app
helm list -A  # En todos los namespaces

# Verificar namespace
kubectl get namespace ecommerce-app

# Recrear si es necesario
kubectl create namespace ecommerce-app
```

### Error: "timed out waiting for the condition"

```bash
# Los pods tardaron mucho en estar listos
# Ver qué pasó

kubectl get pods -n ecommerce-app -o wide
kubectl describe pod <POD_NAME> -n ecommerce-app
kubectl logs <POD_NAME> -n ecommerce-app

# Causas comunes:
# - Image pull error: verificar ACR credentials
# - Insufficient resources: verificar cuotas del cluster
# - Database no accesible: verificar networking
```

### Error: "YAML parse error"

```bash
# Problema en templates YAML
helm lint .  # Mostrará el error

# Verificar valores YAML
helm template ecommerce . | head -50

# Validar YAML específico
kubectl apply -f template.yaml --dry-run=client -o yaml
```

### Debug de valores

```bash
# Ver qué valores se están usando
helm get values ecommerce -n ecommerce-app

# Ver archivo values específico
cat values-prod.yaml

# Verificar override
helm template ecommerce . \
  -f values-prod.yaml \
  --set frontend.replicaCount=10 | grep replicaCount
```

### Logs y eventos

```bash
# Logs del chart
kubectl logs -f deployment/ecommerce-backend -n ecommerce-app

# Eventos del release
kubectl get events -n ecommerce-app --sort-by='.lastTimestamp'

# Debug avanzado
kubectl describe deployment ecommerce-backend -n ecommerce-app
helm get manifest ecommerce -n ecommerce-app | less
```

---

## Enlaces útiles

### Documentación oficial

- **Helm**
  - [Helm Documentation](https://helm.sh/docs/)
  - [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
  - [Helm Template Guide](https://helm.sh/docs/chart_template_guide/)

- **Kubernetes**
  - [Kubernetes Documentation](https://kubernetes.io/docs/)
  - [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
  - [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

- **Azure AKS**
  - [AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
  - [Deploy Helm charts on AKS](https://learn.microsoft.com/en-us/azure/aks/kubernetes-helm)
  - [AKS best practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)

### Herramientas útiles

- [Helm diff plugin](https://github.com/databus23/helm-diff) - Ver diferencias antes de actualizar
- [Helmfile](https://github.com/roboll/helmfile) - Gestionar múltiples releases
- [Chart testing (ct)](https://github.com/helm/chart-testing) - Testing de charts
- [Artifact Hub](https://artifacthub.io/) - Buscar charts públicos

---
