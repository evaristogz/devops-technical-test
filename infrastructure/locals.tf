# Local variables and computed values

locals {
  # Naming prefix: project-environment
  name_prefix = "${var.project_name}-${var.environment}"

  # Common tags applied to all resources
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = "DevOps-Team"
    CostCenter  = "Engineering"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }

  # Network configuration
  vnet_address_space = ["10.0.0.0/16"]
  subnet_ranges = {
    aks     = "10.0.1.0/24"
    appgw   = "10.0.2.0/24"
    db      = "10.0.3.0/24"
    private = "10.0.4.0/24"
  }

  # AKS configuration
  aks_dns_prefix = "${local.name_prefix}-aks"

  # Application Gateway configuration
  appgw_name = "agw-${local.name_prefix}"

  # Key Vault configuration
  kv_name = "kv-${var.project_name}-${var.environment}-${substr(data.azurerm_client_config.current.tenant_id, 0, 8)}"
}
