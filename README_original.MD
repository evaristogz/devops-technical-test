# DevOps Technical Test

## 🎯 Objetivo
Evaluar competencias técnicas en DevOps mediante la implementación de una solución completa en Azure usando Terraform, Kubernetes, Helm y GitHub Actions.

## ⏱️ Duración
**3 horas** desde el momento del fork

## 🚀 Instrucciones para Comenzar

### 1. Fork este repositorio
- Haz fork de este repo en tu cuenta personal
- Clona tu fork localmente
- Crea una nueva rama para tu solución: `git checkout -b solucion-[tu-nombre]`

### 2. Estructura del Proyecto
```
devops-technical-test/
├── infrastructure/          # 🏗️  Terraform para Azure
├── k8s-manifests/          # ☸️  Manifiestos Kubernetes  
├── helm-chart/             # ⚙️  Helm Chart
├── .github/workflows/      # 🔄 GitHub Actions CI/CD
├── src/                    # 💻 Código aplicación (ejemplo)
├── scripts/                # 🔧 Scripts de validación
├── docs/                   # 📚 Documentación adicional
└── README.md               # 📋 Este archivo
```

### 3. Tareas a Completar
Busca comentarios `# TODO:` en todos los archivos y complétalos siguiendo las especificaciones.

**Orden recomendado:**
1. **Terraform** - Infraestructura Azure (35 min)
2. **Kubernetes** - Manifiestos de aplicación (40 min)
3. **Helm** - Chart parametrizable (30 min)
4. **GitHub Actions** - Pipeline CI/CD (40 min)
5. **Documentación** - README y arquitectura (25 min)

### 4. Validación Local
Antes de enviar tu solución, ejecuta:
```bash
./scripts/validate-all.sh
```

### 5. Entrega
- Haz commit de todos tus cambios
- Push a tu rama de solución
- Crea un Pull Request hacia el repo original
- En la descripción del PR incluye:
  - Decisiones arquitectónicas tomadas
  - Supuestos realizados
  - Posibles mejoras futuras

---

## 📋 Especificaciones Técnicas

### Escenario
Desplegar una **aplicación web de e-commerce** con:
- **Frontend**: React app (puerto 3000)
- **Backend API**: Node.js/Express (puerto 8080)
- **Base de datos**: PostgreSQL (Azure Database)
- **Cache**: Redis
- **Storage**: Azure Files para uploads
- **Monitoreo**: Azure Monitor + Application Insights

### Requisitos de Infraestructura (Terraform)
- Resource Group principal
- Virtual Network con 3 subredes:
  - AKS subnet (10.0.1.0/24)  
  - Database subnet (10.0.2.0/24)
  - Application Gateway subnet (10.0.3.0/24)
- AKS cluster con:
  - System node pool (2 nodos)
  - User node pool (3 nodos, auto-scaling)
- Azure Container Registry con integración AKS
- Azure Key Vault para secretos
- Azure Database for PostgreSQL Flexible Server
- Application Gateway para ingress
- Log Analytics Workspace
- Network Security Groups con reglas apropiadas

### Requisitos de Kubernetes
- **Namespace**: `ecommerce-app`
- **Frontend Deployment**:
  - 3 réplicas
  - Resource requests/limits
  - Health checks (liveness, readiness, startup)
  - Rolling update strategy
- **Backend Deployment**:
  - 2 réplicas iniciales
  - HorizontalPodAutoscaler (CPU > 70%)
  - Conexión a PostgreSQL y Redis
  - Secrets desde Azure Key Vault
- **Redis StatefulSet**:
  - 1 réplica con persistent volume
  - Azure Disk storage class
- **Services**: ClusterIP para backend/redis, LoadBalancer para frontend
- **Ingress**: Application Gateway con SSL termination
- **NetworkPolicies**: Microsegmentación entre componentes
- **PodDisruptionBudget**: Para alta disponibilidad
- **ConfigMaps**: Configuración de aplicación por ambiente

### Requisitos de Helm Chart
- Chart.yaml con metadata completa
- Values jerárquicos para dev/staging/prod
- Templates con conditional logic
- Helper functions en _helpers.tpl
- Schema validation (values.schema.json)
- Hooks pre/post-install para database setup
- Tests automatizados de conectividad
- NOTES.txt con instrucciones post-instalación

### Requisitos de CI/CD (GitHub Actions)
- **Triggers**: Push a main/develop, PR a main
- **CI Pipeline**:
  - Terraform validation y security scan
  - Docker multi-arch build (AMD64/ARM64)
  - Container security scanning
  - Unit tests y code coverage
  - Helm chart validation
- **CD Pipeline**:
  - Deploy automático a development (develop branch)
  - Deploy manual a production (main branch)
  - Blue-green deployment strategy
  - Rollback automático en caso de health check failures
- **Azure Integration**:
  - OIDC authentication (sin secretos hardcoded)
  - Push a Azure Container Registry
  - Deploy a AKS usando Helm
  - Notifications a Teams/Slack

---

## ✅ Criterios de Evaluación

### Técnico (70%)
| Componente | Peso | Criterios |
|------------|------|-----------|
| **Terraform** | 25% | Sintaxis, modularidad, seguridad, best practices Azure |
| **Kubernetes** | 25% | Production-ready, security, resource management, integración Azure |
| **Helm** | 20% | Structure, templating, parametrización, testing |
| **CI/CD** | 20% | Pipeline completeness, security, error handling, Azure integration |

### Documentación (20%)
- README comprehensivo
- Decisiones arquitectónicas justificadas
- Instrucciones claras de deployment
- Troubleshooting guide

### Plus Points (10%)
- Optimizaciones de costes
- Monitoring y observability avanzada
- Security hardening adicional
- Performance tuning
- Innovation y mejoras propuestas

---

## 🔧 Herramientas Necesarias

Asegúrate de tener instalado localmente:
```bash
# Terraform
terraform version  # >= 1.0

# Azure CLI  
az version         # >= 2.50

# Kubernetes
kubectl version    # >= 1.28

# Helm
helm version       # >= 3.12

# Docker
docker version     # >= 20.10

# Linting tools (opcional pero recomendado)
tfsec --version
kubeval --version  
actionlint --version
```

---

## 🆘 Troubleshooting

### Problemas Comunes
1. **Terraform validation fails**: Verifica sintaxis y providers
2. **Kubernetes dry-run errors**: Revisa indentación YAML
3. **Helm lint fails**: Valida templating syntax
4. **GitHub Actions syntax**: Usa actionlint para validar

### Scripts de Ayuda
```bash
# Validar todo de una vez
./scripts/validate-all.sh

# Validaciones individuales
./scripts/validate-terraform.sh
./scripts/validate-kubernetes.sh  
./scripts/validate-helm.sh
./scripts/validate-github-actions.sh

# Auto-scoring (solo para referencia)
./scripts/evaluate-submission.sh
```

---

## 📞 Soporte

Si tienes dudas sobre:
- **Especificaciones técnicas**: Lee detenidamente los README
- **Problemas de setup**: Ejecuta scripts de validación
- **Interpretación de requisitos**: Usa tu mejor criterio y documenta decisiones

**Recuerda**: Documenta tus supuestos y decisiones en el PR description.

---

## 🎉 ¡Buena Suerte!

Esta prueba evalúa tanto conocimiento técnico como capacidad de resolución de problemas reales. 

**Tips finales:**
- Lee todos los TODOs antes de empezar
- Prioriza funcionalidad antes que perfección
- Documenta decisiones importantes
- Testa tu solución con los scripts antes de enviar

**Tiempo recomendado por sección:**
- Terraform: 35 min
- Kubernetes: 40 min  
- Helm: 30 min
- CI/CD: 40 min
- Documentación: 25 min
- Buffer: 10 min