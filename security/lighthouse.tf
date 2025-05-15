# Azure Lighthouse Configuration for delegated access

# Resource Group for Lighthouse deployment assets
resource "azurerm_resource_group" "lighthouse" {
  name     = "sec-rg-${var.location}-lighthouse"
  location = var.location
  tags     = merge(var.tags, {
    Environment = "Platform"
    Project     = "Security-Lighthouse"
  })
  provider = azurerm.security_subscription
}

# Register the provider to manage Lighthouse delegations
provider "azapi" {
  alias = "security_subscription"
  subscription_id = var.security_subscription_id
}

# Create a Security Reader Role that can be used for Lighthouse
resource "azurerm_role_definition" "security_reader" {
  name        = "Security Reader"
  scope       = data.azurerm_subscription.security.id
  description = "Can read security-related resources and configurations across subscriptions"

  permissions {
    actions = [
      "Microsoft.Security/*/read",
      "Microsoft.ResourceHealth/*/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/resourceGroups/resources/read",
      "Microsoft.Resources/subscriptions/resources/read",
      "Microsoft.PolicyInsights/*/read",
      "Microsoft.Authorization/policyAssignments/read",
      "Microsoft.Authorization/policyDefinitions/read",
      "Microsoft.Authorization/policySetDefinitions/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.security.id
  ]
  
  provider = azurerm.security_subscription
}

# Setup Lighthouse delegation for the Security Group to workload subscriptions
resource "azapi_resource" "lighthouse_delegation" {
  for_each = local.workload_subscriptions
  
  type      = "Microsoft.ManagedServices/registrationDefinitions@2019-09-01"
  name      = "${each.key}-security-delegation"
  parent_id = each.value.id
  
  body = jsonencode({
    properties = {
      registrationDefinitionName = "Security Team Access - ${each.key}"
      description                = "Allows the security team to monitor resources securely"
      managedByTenantId          = data.azurerm_client_config.current.tenant_id
      authorizations = [
        {
          principalId           = data.azuread_group.security_auditors.object_id
          principalDisplayName  = "Security Auditors"
          roleDefinitionId      = "acdd72a7-3385-48ef-bd42-f606fba81ae7" # Reader
        },
        {
          principalId           = data.azuread_group.security_auditors.object_id
          principalDisplayName  = "Security Auditors"
          roleDefinitionId      = "fb1c8493-542b-48eb-b624-b4c8fea62acd" # Security Reader
        }
      ]
    }
  })
}

# Create a registration assignment for each delegation
resource "azapi_resource" "lighthouse_assignment" {
  for_each = azapi_resource.lighthouse_delegation
  
  type      = "Microsoft.ManagedServices/registrationAssignments@2019-09-01"
  name      = "${each.key}-assignment"
  parent_id = each.value.parent_id
  
  body = jsonencode({
    properties = {
      registrationDefinitionId = jsondecode(each.value.output).id
    }
  })
}