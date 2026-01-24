# Public IP estática para Services tipo LoadBalancer en AKS
resource "azurerm_public_ip" "aks_lb" {
  name                = "pip-aks-lb-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_kubernetes_cluster.main.node_resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}
