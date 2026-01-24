# GitHub Actions OIDC Configuration
# Configuración de autenticación federada entre GitHub Actions y Azure

# Variables locales para la configuración de GitHub
locals {
  github_org            = "evaristogz"
  github_repo           = "devops-technical-test"
  github_develop_branch = "solucion-evaristogz"
  github_main_branch    = "main"
}

# App Registration para GitHub Actions
resource "azuread_application" "github_actions" {
  display_name = "github-actions-${var.project_name}-${var.environment}"
  owners       = [data.azuread_client_config.current.object_id]
}

# Service Principal para la App Registration
resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

# Federated Credential para rama develop (solucion-evaristogz)
resource "azuread_application_federated_identity_credential" "github_develop" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-develop"
  description    = "Federated credential para rama develop (solucion-evaristogz)"

  issuer    = "https://token.actions.githubusercontent.com"
  subject   = "repo:${local.github_org}/${local.github_repo}:ref:refs/heads/${local.github_develop_branch}"
  audiences = ["api://AzureADTokenExchange"]
}

# Federated Credential para rama main
resource "azuread_application_federated_identity_credential" "github_main" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-main"
  description    = "Federated credential para rama main"

  issuer    = "https://token.actions.githubusercontent.com"
  subject   = "repo:${local.github_org}/${local.github_repo}:ref:refs/heads/${local.github_main_branch}"
  audiences = ["api://AzureADTokenExchange"]
}

# Federated Credential para Pull Requests
resource "azuread_application_federated_identity_credential" "github_pr" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-pr"
  description    = "Federated credential para pull requests"

  issuer    = "https://token.actions.githubusercontent.com"
  subject   = "repo:${local.github_org}/${local.github_repo}:pull_request"
  audiences = ["api://AzureADTokenExchange"]
}

# Role Assignment: Contributor para el Service Principal en la suscripción
resource "azurerm_role_assignment" "github_actions_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}
