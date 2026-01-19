# E-commerce Application - DevOps Technical Test

Simple e-commerce application designed for DevOps technical assessment.

## 🏗️ Architecture

- **Frontend**: React SPA (port 3000) with product catalog and shopping cart
- **Backend**: Node.js/Express REST API (port 8080) with health endpoints
- **Database**: PostgreSQL (Azure Database when deployed)
- **Cache**: Redis (Azure Redis when deployed)

## 🚀 Quick Start

### Option 1: Docker Compose (Recommended)
```bash
# Start complete environment
docker-compose up

# Access:
# Frontend: http://localhost:3000
# Backend API: http://localhost:8080
# Health check: http://localhost:8080/health
```

### Option 2: Development Mode
```bash
# Terminal 1 - Backend
cd backend
npm install
npm start

# Terminal 2 - Frontend  
cd frontend
npm install
npm start
```

# 🔍 Health Checks

La aplicación incluye endpoints de health para Kubernetes:

- **Frontend Health:** `GET /health` (endpoint de nginx)
- **Frontend Readiness:** `GET /ready` (endpoint de nginx)
- **Backend Health:** `GET /health` (estado de la aplicación)
- **Backend Readiness:** `GET /ready` (check de dependencias)

---

# 📡 API Endpoints

- `GET /health` – Estado de la aplicación
- `GET /ready` – Readiness check (database, redis)
- `GET /api/products` – Listado de productos
- `POST /api/cart` – Añadir producto al carrito
- `GET /api/cart` – Consultar carrito
- `GET /metrics` – Métricas (uptime, memoria)

---

# 🐳 Container Details

**Frontend**
- Base: `nginx:alpine`
- Puerto: 3000
- Health Check: Built-in nginx health endpoint
- Multi-stage: Build con Node.js → Servido con nginx

**Backend**
- Base: `node:18-alpine`
- Puerto: 8080
- Usuario: Non-root (`nodeuser:1001`)
- Health Check: HTTP GET `/health`

---

# ☸️ Kubernetes Deployment

Aplicación pensada para ejecutarse en Azure AKS.

## Resource Requirements

| Componente | CPU (requests/limits) | RAM (requests/limits) |
|------------|---------------------- |----------------------|
| Frontend   | 100m / 200m           | 128Mi / 256Mi        |
| Backend    | 200m / 500m           | 256Mi / 512Mi        |

## External Dependencies

- **PostgreSQL:** Azure Database for PostgreSQL Flexible Server
- **Redis:** Azure Redis Cache
- **Storage:** Azure Files (para uploads si aplica)

## Health Checks Configuration

**Frontend probe example**
<pre>
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 10
</pre>

**Backend probe example**
<pre>
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
</pre>

---

# 🔧 Environment Variables

**Frontend**
- `REACT_APP_API_URL`: URL de la API (por defecto proxy a localhost:8080)
- `REACT_APP_ENVIRONMENT`: Nombre del entorno a mostrar

**Backend**
- `NODE_ENV`: (development, production)
- `PORT`: Puerto de servicio (por defecto 8080)
- `DATABASE_URL`: Connection string de PostgreSQL
- `REDIS_URL`: Connection string de Redis

---

# 🎯 DevOps Testing Focus

Esta app es simple y permite centrarse en:

- Infraestructura como código: Terraform en Azure
- Orquestación de contenedores: Kubernetes manifests/configuración
- Gestión de paquetes: Helm charts y templating
- CI/CD: GitHub Actions con integración Azure
- Observabilidad: Health checks, logging, monitoring

---

# 🐛 Troubleshooting Common Issues

**Frontend muestra "Loading..." para siempre**
<pre>
# Verifica si el backend está corriendo
curl http://localhost:8080/health
# Revisa errores en la consola del navegador
# Verifica la config de proxy en package.json
</pre>

**Errores en Backend API**
<pre>
# Revisa los logs del backend
docker-compose logs backend
# Verifica variables de entorno
docker-compose exec backend env | grep NODE
</pre>

**Problemas de conexión a base de datos**
<pre>
# Revisa logs de PostgreSQL
docker-compose logs postgres
# Verifica formato de DATABASE_URL:
# postgresql://user:password@host:port/database
</pre>

**Debug salud**
<pre>
# Test endpoints de salud
curl -v http://localhost:3000/health       # healthy
curl -v http://localhost:8080/health       # status JSON
curl -v http://localhost:8080/ready        # dependencias
</pre>

---

# 📊 Monitoring

El endpoint `/metrics` expone métricas como:
<pre>
{
  "uptime": 3661.234,
  "memory": {
    "rss": 45678592,
    "heapTotal": 29360128,
    "heapUsed": 15982736
  },
  "pid": 1,
  "timestamp": "2025-09-04T10:27:00.000Z"
}
</pre>

---

# 🔒 Security Features

- **Helmet.js**: Security headers
- **CORS**: Configuración cross-origin
- **Non-root containers**: Ambos contenedores corren sin root
- **Read-only filesystem**: Donde sea posible
- **No hardcoded secrets**: Uso de variables de entorno

---

# 📈 Scaling Considerations

- **Stateless:** Escala horizontalmente sin estado
- **Session storage:** Persistir sesión en Redis (cuando se implemente)
- **Database:** Servicio PostgreSQL para persistencia de datos
- **CDN:** Frontend puede servirse vía CDN
- **Load balancing:** Backend API es stateless y se balancea fácilmente

---
