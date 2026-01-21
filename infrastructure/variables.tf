# Variables for Azure E-commerce Infrastructure

# Environment configuration
variable "environment" {
  description = "Entorno (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Solo se permiten los valores: dev, staging, prod."
  }
}

variable "location" {
  description = "Región de Azure para los recursos"
  type        = string
  default     = "West Europe"

  validation {
    condition     = can(regex("^[A-Za-z ]+$", var.location))
    error_message = "La localización debe contener solo letras y espacios."
  }
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "ecommerce"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "El nombre del proyecto solo debe contener letras minúsculas, números y guiones."
  }
}

# TODO: Add variables for AKS configuration
# - aks_node_count (number, default 2, min 1, max 5)
# - aks_vm_size (string, default "Standard_DS2_v2")
# - aks_auto_scaling (bool, default true)
# - aks_min_count (number, default 2)  
# - aks_max_count (number, default 5)

variable "aks_system_node_count" {
  description = "Número de nodos en el pool de AKS"
  type        = number
  default     = 2
}

variable "aks_user_node_count" {
  description = "Número de nodos en el pool de nodos de usuario de AKS"
  type        = number
  default     = 3
}

variable "aks_vm_size" {
  description = "Tamaño de las VMs para los nodos de AKS"
  type        = string
  default     = "Standard_DS2_v2" # 2 CPUs, 7GB RAM
  #default = "Standard_B2s" # 2 CPUs, 4GB RAM (Alternativa a usar en tfvars)
}

variable "aks_auto_scaling_enabled" {
  description = "Habilitar autoescalado para AKS"
  type        = bool
  default     = true
}

variable "aks_min_count" {
  description = "Número mínimo de nodos en el pool de AKS"
  type        = number
  default     = 2
}

variable "aks_max_count" {
  description = "Número máximo de nodos en el pool de AKS"
  type        = number
  default     = 5
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes para AKS"
  type        = string
  default     = "1.33.5" # Predeterminada a fecha de enero 2026.
}

variable "aks_os_disk_size_gb" {
  description = "Tamaño del disco OS de los nodos AKS en GB"
  type        = number
  default     = 25
}

variable "aks_load_balancer_sku" {
  description = "SKU del Load Balancer para AKS"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["basic", "standard"], lower(var.aks_load_balancer_sku))
    error_message = "El SKU debe ser: basic o standard."
  }
}

variable "aks_service_cidr" {
  description = "CIDR para los servicios de Kubernetes"
  type        = string
  default     = "10.1.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "IP del servicio DNS de Kubernetes"
  type        = string
  default     = "10.1.0.10"
}



# TODO: Add variables for database configuration
# - postgres_sku_name (string, default "B_Standard_B1ms")
# - postgres_storage_mb (number, default 32768)
# - postgres_backup_retention_days (number, default 7)
# - postgres_admin_username (string, default "pgadmin")

variable "postgres_sku_name" {
  description = "Nombre SKU del servidor PostgreSQL"
  type        = string
  default     = "B_Standard_B1ms" # 1 vCPU, 2GM RAM 
  #default = "B_Standard_B1s" # 1 vCPU, 1GM RAM (Alternativa a usar en tfvars)
}

variable "postgres_storage_mb" {
  description = "Tamaño de almacenamiento del servidor PostgreSQL, en MB"
  type        = number
  default     = 32768 # 32GB
}

variable "postgres_backup_retention_days" {
  description = "Días de retención de backups para PostgreSQL"
  type        = number
  default     = 7
}

variable "postgres_admin_username" {
  description = "Nombre de usuario administrador para PostgreSQL"
  type        = string
  default     = "pgadmin"
  sensitive   = true
}

variable "postgres_admin_password" {
  description = "Contraseña del usuario administrador para PostgreSQL"
  type        = string
  default     = "PasswordTEMPORAL123!"
  sensitive   = true
}

variable "postgres_version" {
  description = "Versión de PostgreSQL Flexible Server"
  type        = string
  default     = "17" # Disponible versión 18 a fecha de enero 2026
}



# TODO: Add variables for Application Gateway
# - app_gateway_sku_name (string, default "Standard_v2")
# - app_gateway_sku_tier (string, default "Standard_v2")
# - app_gateway_capacity (number, default 2)

variable "app_gateway_sku_name" {
  description = "Nombre SKU del Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "app_gateway_sku_tier" {
  description = "Nivel del Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "app_gateway_capacity" {
  description = "Capacidad del Application Gateway"
  type        = number
  default     = 2
}

variable "log_analytics_sku" {
  description = "SKU del Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"

  validation {
    condition     = contains(["Free", "Standard", "Premium", "PerGB2018", "Standalone"], var.log_analytics_sku)
    error_message = "El SKU debe ser: Free, Standard, Premium, PerGB2018, o Standalone."
  }
}

variable "log_analytics_retention_days" {
  description = "Días de retención de logs en Log Analytics"
  type        = number
  default     = 30
}

variable "enable_application_insights" {
  description = "Habilitar Application Insights"
  type        = bool
  default     = true
}

# TODO: Add variables for networking
# - vnet_address_space (list(string), default ["10.0.0.0/16"])
# - aks_subnet_address_prefix (string, default "10.0.1.0/24")
# - db_subnet_address_prefix (string, default "10.0.2.0/24")  
# - agw_subnet_address_prefix (string, default "10.0.3.0/24")

variable "vnet_address_space" {
  description = "Rango IP para la red virtual"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_address_prefix" {
  description = "Subnet para AKS"
  type        = string
  default     = "10.0.1.0/24"
}

variable "db_subnet_address_prefix" {
  description = "Subnet para base de datos"
  type        = string
  default     = "10.0.2.0/24"
}

variable "agw_subnet_address_prefix" {
  description = "Subnet para Application Gateway"
  type        = string
  default     = "10.0.3.0/24"
}


# Variables para Azure Container Registry (ACR)
variable "acr_sku" {
  description = "SKU del Azure Container Registry"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "El SKU debe ser: Basic, Standard, o Premium."
  }
}

variable "acr_admin_enabled" {
  description = "Habilitar cuenta admin en ACR (menos seguro)"
  type        = bool
  default     = false
}

# Locals for resource naming and tagging
locals {
  # TODO: Define naming convention
  # name_prefix = "${var.project_name}-${var.environment}"

  # TODO: Define common tags
  # common_tags = {
  #   Environment = var.environment
  #   Project     = var.project_name
  #   ManagedBy   = "Terraform"
  #   Owner       = "DevOps-Team"
  #   CostCenter  = "Engineering"
  # 
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = "DevOps-Team"
    CostCenter  = "Engineering"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}