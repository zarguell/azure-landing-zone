# Management Group Structure

# Root Management Group (Tenant Root Group)
# This is automatically created in Azure, so we'll just reference it
data "azurerm_management_group" "root" {
  name = data.azurerm_client_config.current.tenant_id
}

data "azurerm_client_config" "current" {}

# Platform Management Group
resource "azurerm_management_group" "platform" {
  display_name               = "Platform"
  parent_management_group_id = data.azurerm_management_group.root.id
  
  details {
    description = "Contains all platform and shared services subscriptions"
  }
}

# Workloads Management Group
resource "azurerm_management_group" "workloads" {
  display_name               = "Workloads"
  parent_management_group_id = data.azurerm_management_group.root.id
  
  details {
    description = "Contains all workload subscriptions"
  }
}

# Dev Management Group
resource "azurerm_management_group" "dev" {
  display_name               = "Dev"
  parent_management_group_id = azurerm_management_group.workloads.id
  
  details {
    description = "Contains all development environments"
  }
}

# Prod Management Group
resource "azurerm_management_group" "prod" {
  display_name               = "Prod"
  parent_management_group_id = azurerm_management_group.workloads.id
  
  details {
    description = "Contains all production environments"
  }
}

# Management Group Subscription Association
# Note: These resources assume subscriptions have been created manually
resource "azurerm_management_group_subscription_association" "security" {
  management_group_id = azurerm_management_group.platform.id
  subscription_id     = data.azurerm_subscription.security.id
}

# Dynamic association for workload subscriptions
resource "azurerm_management_group_subscription_association" "workloads" {
  for_each = local.workload_subscriptions
  
  management_group_id = each.value.type == "Dev" ? azurerm_management_group.dev.id : azurerm_management_group.prod.id
  subscription_id     = each.value.id
}

# RBAC Configuration

# AAD Groups - NOTE: These need to be created manually in Azure AD
# Here we're just referencing them by display name
data "azuread_group" "platform_admins" {
  display_name = "PlatformAdmins"
}

data "azuread_group" "security_auditors" {
  display_name = "SecurityAuditors"
}

data "azuread_group" "workload_owners" {
  display_name = "WorkloadOwners"
}

# Role Assignments at Management Group Level
resource "azurerm_role_assignment" "platform_admins_contributor" {
  scope                = azurerm_management_group.platform.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_group.platform_admins.object_id
}

resource "azurerm_role_assignment" "security_auditors_reader" {
  scope                = data.azurerm_management_group.root.id
  role_definition_name = "Reader"
  principal_id         = data.azuread_group.security_auditors.object_id
}

resource "azurerm_role_assignment" "workload_owners_contributor" {
  scope                = azurerm_management_group.workloads.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_group.workload_owners.object_id
}

# Security Auditor custom role for monitoring compliance
resource "azurerm_role_definition" "security_auditor" {
  name        = "Security Auditor"
  scope       = data.azurerm_management_group.root.id
  description = "Can view security-related resources and configurations"

  permissions {
    actions = [
      "Microsoft.Security/*/read",
      "Microsoft.PolicyInsights/*/read",
      "Microsoft.Authorization/policyAssignments/read",
      "Microsoft.Authorization/policyDefinitions/read",
      "Microsoft.Authorization/policySetDefinitions/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_management_group.root.id
  ]
}

# Assign Security Auditor role to Security Auditors group
resource "azurerm_role_assignment" "security_auditors_custom" {
  scope              = data.azurerm_management_group.root.id
  role_definition_id = azurerm_role_definition.security_auditor.role_definition_resource_id
  principal_id       = data.azuread_group.security_auditors.object_id
}