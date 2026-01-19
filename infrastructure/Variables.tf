# Variables for Azure E-commerce Infrastructure

# Environment configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
  
  validation {
    condition = can(regex("^[A-Za-z ]+$", var.location))
    error_message = "Location must be a valid Azure region name."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "ecommerce"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

# TODO: Add variables for AKS configuration
# - aks_node_count (number, default 2, min 1, max 5)
# - aks_vm_size (string, default "Standard_DS2_v2")
# - aks_auto_scaling (bool, default true)
# - aks_min_count (number, default 2)  
# - aks_max_count (number, default 5)

# TODO: Add variables for database configuration
# - postgres_sku_name (string, default "B_Standard_B1ms")
# - postgres_storage_mb (number, default 32768)
# - postgres_backup_retention_days (number, default 7)
# - postgres_admin_username (string, default "pgadmin")

# TODO: Add variables for Application Gateway
# - app_gateway_sku_name (string, default "Standard_v2")
# - app_gateway_sku_tier (string, default "Standard_v2")
# - app_gateway_capacity (number, default 2)

# TODO: Add variables for monitoring
# - log_analytics_retention_days (number, default 30)
# - enable_application_insights (bool, default true)

# TODO: Add variables for networking
# - vnet_address_space (list(string), default ["10.0.0.0/16"])
# - aks_subnet_address_prefix (string, default "10.0.1.0/24")
# - db_subnet_address_prefix (string, default "10.0.2.0/24")  
# - agw_subnet_address_prefix (string, default "10.0.3.0/24")

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
  # }
}