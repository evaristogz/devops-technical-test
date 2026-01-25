# Kubernetes Manifests - E-commerce Application

> **[Volver al README.md principal del repositorio](../README.MD)** 

## Descripción

Este directorio contiene todos los **manifiestos de Kubernetes** necesarios para desplegar la aplicación de e-commerce en Azure Kubernetes Service (AKS). Los manifiestos están organizados por componentes y definen toda la infraestructura necesaria incluyendo deployments, services, configuración, seguridad y políticas de red.

---

## Tabla de contenidos

1. [Estructura del directorio](#estructura-del-directorio)
2. [Recursos core](#recursos-core)
3. [Componentes frontend](#componentes-frontend)
4. [Componentes backend](#componentes-backend)
5. [Componentes redis](#componentes-redis)
6. [Seguridad y red](#seguridad-y-red)
7. [Requisitos técnicos detallados](#requisitos-técnicos-detallados)
8. [Guía de despliegue manual en AKS](#guía-de-despliegue-manual-en-aks)
9. [Validación](#validación)
10. [Solución de problemas](#solución-de-problemas)
11. [Enlaces útiles](#enlaces-útiles)

---

## Estructura del directorio

```
k8s-manifests/
├── configmap.yaml              # Configuración de la aplicación
├── namespace.yaml              # Namespace ecommerce-app
├── secret.yaml                 # Secrets (credenciales sensibles)
├── serviceaccounts.yaml        # Service Accounts + Azure Workload Identity
├── networkpolicy.yaml          # Políticas de red (microsegmentación)
├── pdb.yaml                    # Pod Disruption Budgets (HA)
├── README.md                   # Este archivo
│
├── backend/                    # Componentes Backend (Node.js API)
│   ├── deployment.yaml         # Deployment con 2+ réplicas
│   ├── service.yaml            # ClusterIP Service
│   └── hpa.yaml                # HorizontalPodAutoscaler (CPU > 70%)
│
├── frontend/                   # Componentes Frontend (React App)
│   ├── deployment.yaml         # Deployment con 3 réplicas
│   ├── service.yaml            # LoadBalancer/ClusterIP Service
│   └── hpa.yaml                # HorizontalPodAutoscaler
│
├── redis/                      # Componentes Redis (Cache)
│   ├── statefulset.yaml        # StatefulSet para persistencia
│   ├── service.yaml            # Headless Service
│   └── pvc.yaml                # PersistentVolumeClaim (Azure Disk)
│
└── gateway/                    # API Gateway (Kubernetes Gateway API)
    ├── gateway.yaml            # Gateway resource
    └── httproutes.yaml         # HTTPRoute resources
```

---

## Recursos core

### namespace.yaml
- **Nombre**: `ecommerce-app`
- **Labels**: Apropiados para Azure Workload Identity
- **Pod Security Standards**: `restricted`
- **Descripción**: Define el namespace aislado para toda la aplicación

### configmap.yaml
- **Propósito**: Almacena configuración no sensible
- **Contenido**:
  - Variables de entorno de aplicación
  - URLs de servicios
  - Configuración por ambiente
  - Flags de características

### secret.yaml
- **Propósito**: Almacena credenciales y datos sensibles
- **Alternativa Recomendada**: [SecretProviderClass](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver)
- **Contenido**:
  - Credenciales de base de datos
  - API keys
  - Tokens de autenticación

### serviceaccounts.yaml
- **Integración**: Azure Workload Identity
- **Service Accounts**:
  - `backend-sa`: Para backend API
  - `frontend-sa`: Para frontend
  - `redis-sa`: Para Redis (si es necesario)

---

## Componentes frontend

Aplicación React que sirve la interfaz de usuario.

### Especificaciones

| Aspecto | Valor |
|--------|-------|
| **Imagen** | `<ACR_NAME>.azurecr.io/ecommerce-frontend:latest` |
| **Puerto** | 3000 |
| **Réplicas** | 3 (mínimo) |
| **Requests** | CPU: 100m, Memory: 128Mi |
| **Limits** | CPU: 200m, Memory: 256Mi |
| **Actualización** | RollingUpdate (maxSurge: 1, maxUnavailable: 0) |

### Health Checks

```yaml
Liveness:  GET /health → port 3000 (30s delay, 10s timeout)
Readiness: GET /ready → port 3000 (10s delay, 5s timeout)
Startup:   GET / → port 3000 (failureThreshold: 30)
```

### Variables de Entorno

```env
REACT_APP_API_URL=http://backend-service:8080/api
REACT_APP_ENVIRONMENT=production
REACT_APP_FEATURES=checkout,recommendations
```

### Anti-affinity

```yaml
podAntiAffinity: preferredDuringSchedulingIgnoredDuringExecution
  - Distribución en múltiples nodos
  - Mejor disponibilidad
```

---

## Componentes backend

API Node.js/Express que procesa lógica de negocio.

### Especificaciones

| Aspecto | Valor |
|--------|-------|
| **Imagen** | `<ACR_NAME>.azurecr.io/ecommerce-backend:latest` |
| **Puerto** | 8080 |
| **Réplicas** | 2-5 (con HPA) |
| **Requests** | CPU: 200m, Memory: 256Mi |
| **Limits** | CPU: 500m, Memory: 512Mi |
| **Auto-scaling** | Basado en CPU > 70% |

### Health Checks

```yaml
Liveness:  GET /health → port 8080 (30s delay, 10s timeout)
Readiness: GET /ready → port 8080 (15s delay, 5s timeout)
Startup:   GET /health → port 8080 (failureThreshold: 20)
```

### Variables de Entorno

```env
NODE_ENV=production
DATABASE_URL=postgresql://user:password@db.postgres.database.azure.com/ecommerce
REDIS_URL=redis://redis-service:6379
DATABASE_POOL_MAX=10
LOG_LEVEL=info
```

### Conexiones

- **PostgreSQL**: Azure Database for PostgreSQL Flexible Server
- **Redis**: Cache interno (StatefulSet)
- **Azure Files**: Storage para uploads
- **Application Insights**: Telemetría

### HPA (HorizontalPodAutoscaler)

```yaml
Target: CPU Utilization > 70%
Min Replicas: 2
Max Replicas: 5
Behavior:
  Scale Up: 1 pod/min (custom metric)
  Scale Down: 1 pod/min (cooldown: 5min)
```

---

## Componentes redis

Cache de datos y sesiones en memoria.

### Especificaciones

| Aspecto | Valor |
|--------|-------|
| **Imagen** | `redis:7-alpine` |
| **Puerto** | 6379 |
| **Réplicas** | 1 (StatefulSet) |
| **Storage** | 1Gi (Azure Disk) |
| **Requests** | CPU: 100m, Memory: 128Mi |
| **Limits** | CPU: 200m, Memory: 256Mi |

### Persistencia

```yaml
Storage Class: Azure Disk
PVC: redis-data (1Gi)
Persistence:
  enabled: true
  size: 1Gi
  storageClassName: managed-premium
```

### ConfigMap Redis

```conf
maxmemory: 256mb
maxmemory-policy: allkeys-lru
save: 300 10 (snapshot cada 5 min)
appendonly: yes
```

### Health Checks

```yaml
Liveness:  redis-cli ping → 30s delay
Readiness: redis-cli ping → 5s delay
```

---

## Seguridad y red

### SecurityContext

Aplicado a todos los pods:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 2000
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
```

### NetworkPolicy

Control de tráfico entre componentes:

```
Frontend ─────────────► Backend
                          │
                          ├─────► Redis
                          └─────► PostgreSQL
```

**Reglas**:
- Frontend → Backend (puerto 8080)
- Backend → Redis (puerto 6379)
- Backend → PostgreSQL (puerto 5432)
- Todos → DNS (puerto 53)
- Entrada desde Application Gateway

### RBAC

Mínimos permisos necesarios en ServiceAccounts.

### Azure Workload Identity

Integración segura sin almacenar credenciales:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: <CLIENT_ID>
```

### Pod Security Standards

```yaml
labels:
  pod-security.kubernetes.io/enforce: restricted
  pod-security.kubernetes.io/audit: restricted
  pod-security.kubernetes.io/warn: restricted
```

### Pod Disruption Budgets

Aseguran disponibilidad durante mantenimiento:

```yaml
Frontend PDB: maxUnavailable: 1
Backend PDB:  maxUnavailable: 1
Redis PDB:    maxUnavailable: 0 (StatefulSet crítico)
```

---

## Requisitos técnicos detallados

### Namespace
- Nombre: `ecommerce-app`
- Labels para Workload Identity
- Pod Security Standards: `restricted`
- Network policies habilitadas
- Resource quotas (recomendado)

### Frontend (React)
- 3 réplicas mínimo
- Resource requests y limits
- Liveness/Readiness/Startup probes
- Rolling update strategy
- Anti-affinity entre pods
- Service (LoadBalancer o Ingress)

### Backend (Node.js)
- 2 réplicas base, hasta 5 con HPA
- Conexión a PostgreSQL y Redis
- Secrets desde Azure Key Vault (via SecretProviderClass)
- Health checks tri-fase
- Resource requests y limits
- Environment variables desde ConfigMap/Secrets

### Redis
- StatefulSet con 1 réplica
- PersistentVolume (Azure Disk)
- Service headless o clusterIP
- Resource limits configurados

### Integración Azure
- SecretProviderClass para Azure Key Vault
- Storage Class para Azure Disk
- Azure Workload Identity en ServiceAccounts
- Application Insights sidecar (opcional pero recomendado)
- Network policies para microsegmentación

---

## Guía de despliegue manual en AKS

### Prerequisitos

```bash
# Verificar acceso a AKS
az aks get-credentials --resource-group <RG> --name <AKS_NAME>

# Verificar conexión
kubectl cluster-info
kubectl get nodes

# Requerimientos de imagen
az acr list --query [].loginServer -o table
```

### Paso 1: Validar Manifiestos

```bash
# Validar sintaxis YAML
kubectl apply -f k8s-manifests/ --dry-run=client

# Validar contra cluster (recomendado)
kubectl apply -f k8s-manifests/ --dry-run=server

# Lint con kubeval
kubeval k8s-manifests/namespace.yaml
kubeval k8s-manifests/backend/deployment.yaml
```

### Paso 2: Crear Namespace y Secrets

```bash
# Crear namespace
kubectl apply -f k8s-manifests/namespace.yaml

# Configurar SecretProviderClass (Azure Key Vault)
kubectl apply -f k8s-manifests/secret.yaml

# Verificar
kubectl get namespace ecommerce-app
kubectl get secretproviderclass -n ecommerce-app
```

### Paso 3: Desplegar Core Resources

```bash
# ConfigMap y ServiceAccounts
kubectl apply -f k8s-manifests/configmap.yaml
kubectl apply -f k8s-manifests/serviceaccounts.yaml

# Network Policies
kubectl apply -f k8s-manifests/networkpolicy.yaml

# Verificar
kubectl get configmap -n ecommerce-app
kubectl get sa -n ecommerce-app
```

### Paso 4: Desplegar Redis

```bash
# Redis PVC, Service y StatefulSet
kubectl apply -f k8s-manifests/redis/pvc.yaml
kubectl apply -f k8s-manifests/redis/service.yaml
kubectl apply -f k8s-manifests/redis/statefulset.yaml

# Esperar a que esté listo
kubectl rollout status statefulset/redis -n ecommerce-app

# Verificar
kubectl get pvc,svc,statefulset -n ecommerce-app
```

### Paso 5: Desplegar Backend

```bash
# Backend Deployment, Service y HPA
kubectl apply -f k8s-manifests/backend/deployment.yaml
kubectl apply -f k8s-manifests/backend/service.yaml
kubectl apply -f k8s-manifests/backend/hpa.yaml

# Esperar a que esté listo
kubectl rollout status deployment/backend -n ecommerce-app

# Verificar logs
kubectl logs -f deployment/backend -n ecommerce-app --tail=50
```

### Paso 6: Desplegar Frontend

```bash
# Frontend Deployment, Service y HPA
kubectl apply -f k8s-manifests/frontend/deployment.yaml
kubectl apply -f k8s-manifests/frontend/service.yaml
kubectl apply -f k8s-manifests/frontend/hpa.yaml

# Esperar a que esté listo
kubectl rollout status deployment/frontend -n ecommerce-app

# Obtener IP externa
kubectl get svc frontend -n ecommerce-app
```

### Paso 7: Configurar Ingress/Gateway

```bash
# Aplicar Application Gateway Ingress o Kubernetes Gateway API
kubectl apply -f k8s-manifests/gateway/gateway.yaml
kubectl apply -f k8s-manifests/gateway/httproutes.yaml

# Verificar
kubectl get ingress -n ecommerce-app
kubectl get gateway,httproute -n ecommerce-app
```

### Paso 8: Aplicar PDB

```bash
# Pod Disruption Budgets
kubectl apply -f k8s-manifests/pdb.yaml

# Verificar
kubectl get pdb -n ecommerce-app
```

### Verificación Completa

```bash
# Todos los recursos
kubectl get all -n ecommerce-app

# Pods en ejecución
kubectl get pods -n ecommerce-app -o wide

# Eventos recientes
kubectl get events -n ecommerce-app --sort-by='.lastTimestamp'

# Describir recursos problemáticos
kubectl describe pod <POD_NAME> -n ecommerce-app
```

---

## Validación

```bash
# Validar health checks
kubectl logs deployment/backend -n ecommerce-app
kubectl exec redis-0 -n ecommerce-app -- redis-cli ping
```

```bash
# Frontend
kubectl port-forward svc/frontend 3000:3000 -n ecommerce-app
curl http://localhost:3000/health

# Backend
kubectl port-forward svc/backend 8080:8080 -n ecommerce-app
curl http://localhost:8080/health

# Redis
kubectl exec redis-0 -n ecommerce-app -- redis-cli ping
kubectl exec redis-0 -n ecommerce-app -- redis-cli INFO
```

### Verificar Auto-scaling

```bash
# Ver HPA status
kubectl get hpa -n ecommerce-app

# Monitor de métricas
kubectl top nodes
kubectl top pods -n ecommerce-app

# Simular carga (para testing)
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://backend-service:8080/api/products; done"
```

---

## Solución de problemas

### Pod no inicia

```bash
# Revisar logs
kubectl logs <POD_NAME> -n ecommerce-app
kubectl logs <POD_NAME> -n ecommerce-app --previous

# Describir eventos
kubectl describe pod <POD_NAME> -n ecommerce-app

# Causas comunes:
# - Image pull errors: Verificar ACR credentials
# - Secrets no encontrados: Validar SecretProviderClass
# - Resource limits: Aumentar requests/limits
```

### Conectividad entre servicios

```bash
# Probar desde un pod
kubectl exec -it <POD_NAME> -n ecommerce-app -- bash

# Dentro del pod:
curl http://backend-service:8080/health   # Probar backend
redis-cli -h redis-service ping           # Probar Redis
psql -h <DB_HOSTNAME> -U postgres         # Probar BD
```

### HPA no escala

```bash
# Verificar métricas disponibles
kubectl get hpa -n ecommerce-app --watch

# Verificar metrics-server
kubectl get deployment metrics-server -n kube-system

# Ver detalles de HPA
kubectl describe hpa backend -n ecommerce-app

# Generar carga:
kubectl run -i --tty load-gen --rm --image=busybox -- /bin/sh -c "while true; do wget -q -O- http://backend-service:8080/api/test; done"
```

### Network Policy bloquea tráfico

```bash
# Verificar políticas
kubectl get networkpolicy -n ecommerce-app

# Revisar logs del CNI (Calico, Cilium, etc.)
kubectl logs -n calico-system <POD_NAME>

# Temporalmente deshabilitar para testing
kubectl delete networkpolicy --all -n ecommerce-app  # ⚠️ Solo para testing
```

### Secrets no disponibles

```bash
# Verificar SecretProviderClass
kubectl describe secretproviderclass -n ecommerce-app

# Revisar logs del CSI driver
kubectl logs -n kube-system -l app=secrets-store-csi-driver

# Verificar permisos en Azure Key Vault
az keyvault secret list --vault-name <VAULT_NAME>

# Test manual
kubectl exec -it <POD_NAME> -n ecommerce-app -- cat /mnt/secrets-store/db-password
```

---

## Enlaces útiles

### Documentación oficial

- **Kubernetes**
  - [Kubernetes Documentation](https://kubernetes.io/docs/)
  - [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
  - [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
  
- **Azure Kubernetes Service (AKS)**
  - [AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
  - [Azure Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview)
  - [Secrets Store CSI Driver](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver)
  - [AKS Best Practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)

- **Seguridad**
  - [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
  - [SecurityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
  - [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
  - [Pod Disruption Budgets](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)

- **Herramientas y Validación**
  - [kubectl CLI](https://kubernetes.io/docs/reference/kubectl/)
  - [kubeval - YAML validator](https://www.kubeval.com/)
  - [kube-bench - Security audit](https://github.com/aquasecurity/kube-bench)
  - [Polaris - Best practices audit](https://www.fairwinds.com/polaris)

### Recursos Azure Específicos

- [Azure Container Registry (ACR)](https://learn.microsoft.com/en-us/azure/container-registry/)
- [Azure Database for PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/)
- [Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/)
- [Application Gateway Ingress Controller](https://learn.microsoft.com/en-us/azure/application-gateway/ingress-controller-overview)