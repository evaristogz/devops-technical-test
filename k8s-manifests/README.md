# Kubernetes Manifests for E-commerce Application

Este directorio contiene todos los manifiestos de Kubernetes necesarios para desplegar la aplicación de e-commerce.

## 📋 Estructura Requerida

Debes crear los siguientes archivos:

### Core Resources
- `namespace.yaml` - Namespace de la aplicación
- `configmap.yaml` - Configuración de la aplicación
- `secret.yaml` - Secrets (o SecretProviderClass para Azure Key Vault)

### Frontend Components
- `frontend/deployment.yaml` - Deployment del frontend React
- `frontend/service.yaml` - Service para el frontend
- `frontend/hpa.yaml` - HorizontalPodAutoscaler

### Backend Components  
- `backend/deployment.yaml` - Deployment del backend API
- `backend/service.yaml` - Service para el backend
- `backend/hpa.yaml` - HorizontalPodAutoscaler

### Redis Components
- `redis/statefulset.yaml` - StatefulSet para Redis
- `redis/service.yaml` - Service para Redis
- `redis/pvc.yaml` - PersistentVolumeClaim

### Network & Security
- `ingress.yaml` - Application Gateway Ingress
- `networkpolicy.yaml` - Network policies para microsegmentación  
- `pdb.yaml` - Pod Disruption Budgets

## 🎯 Requisitos Técnicos

### Namespace
- Nombre: `ecommerce-app`
- Labels apropiados para Azure Workload Identity
- Pod Security Standards: `restricted`

### Frontend (React App)
- **Imagen**: `<ACR_NAME>.azurecr.io/ecommerce-frontend:latest`
- **Puerto**: 3000
- **Réplicas**: 3
- **Resources**:
  - Requests: CPU 100m, Memory 128Mi
  - Limits: CPU 200m, Memory 256Mi
- **Health Checks**:
  - Liveness: HTTP GET `/health` port 3000
  - Readiness: HTTP GET `/ready` port 3000
  - Startup: HTTP GET `/` port 3000 (failureThreshold: 30)
- **Environment Variables**:
  - `REACT_APP_API_URL`: URL del backend
  - `REACT_APP_ENVIRONMENT`: from ConfigMap

### Backend (Node.js API)
- **Imagen**: `<ACR_NAME>.azurecr.io/ecommerce-backend:latest`  
- **Puerto**: 8080
- **Réplicas**: 2 (auto-scaling hasta 5)
- **Resources**:
  - Requests: CPU 200m, Memory 256Mi
  - Limits: CPU 500m, Memory 512Mi
- **Health Checks**:
  - Liveness: HTTP GET `/health` port 8080
  - Readiness: HTTP GET `/ready` port 8080  
  - Startup: HTTP GET `/health` port 8080 (failureThreshold: 20)
- **Environment Variables**:
  - `DATABASE_URL`: Connection string from Secret
  - `REDIS_URL`: Redis connection string
  - `NODE_ENV`: from ConfigMap
- **HPA**: Scale based on CPU > 70%

### Redis Cache
- **Imagen**: `redis:7-alpine`
- **Puerto**: 6379
- **Storage**: 1Gi PersistentVolume (Azure Disk)
- **Resources**:
  - Requests: CPU 100m, Memory 128Mi
  - Limits: CPU 200m, Memory 256Mi

### Security Requirements
- **SecurityContext**: runAsNonRoot: true, runAsUser: 1001
- **Capabilities**: drop ALL capabilities
- **ReadOnlyRootFilesystem**: true (where possible)
- **ServiceAccount**: Use Azure Workload Identity
- **NetworkPolicies**:
  - Frontend can only talk to Backend
  - Backend can only talk to Redis and Database
  - All pods can access DNS

### High Availability
- **PodDisruptionBudget**: maxUnavailable: 1 para frontend y backend
- **Anti-affinity**: Spread pods across nodes
- **Rolling Updates**: maxSurge: 1, maxUnavailable: 0

### Azure Integration
- **SecretProviderClass**: Para obtener secrets desde Azure Key Vault
- **Storage Class**: Azure Disk para Redis
- **Ingress**: Application Gateway Ingress Controller annotations

## 📝 TODO Checklist

Para cada archivo que crees, asegúrate de incluir:

- [ ] Labels consistentes (`app`, `component`, `version`)
- [ ] Resource requests y limits apropiados
- [ ] Health checks completos (liveness, readiness, startup)
- [ ] Security contexts configurados
- [ ] Environment variables desde ConfigMaps/Secrets
- [ ] Annotations para Azure services
- [ ] Selectors correctos entre recursos relacionados

## 🔍 Validación

Una vez completados los manifiestos, valida con:

```bash
# Sintaxis básica
kubectl --dry-run=client apply -f k8s-manifests/

# Validación avanzada (si tienes las herramientas)
kubeval k8s-manifests/**/*.yaml
kube-score score k8s-manifests/**/*.yaml
```

## 💡 Consejos

1. **Usar referencias**: Los Services deben referenciar correctamente los Deployments/StatefulSets
2. **Consistent naming**: Usa un esquema de nombres consistente
3. **Resource efficiency**: No sobre-provisionar resources en un environment de test
4. **Security first**: Implementa security contexts aunque sea más trabajo
5. **Monitoring ready**: Incluye labels y annotations para monitoring