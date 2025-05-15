# Policy Definitions

# Deny Public IP Creation
resource "azurerm_policy_definition" "deny_public_ip" {
  name                = "deny-public-ip-creation"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "Deny creation of Public IPs"
  description         = "This policy denies the creation of Public IPs across the organization"
  management_group_id = data.azurerm_management_group.root.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "field": "type",
    "equals": "Microsoft.Network/publicIPAddresses"
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
}

# Deny Non-Approved Regions
resource "azurerm_policy_definition" "allowed_locations" {
  name                = "allowed-locations"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "Allowed Locations"
  description         = "This policy restricts deployments to approved Azure regions"
  management_group_id = data.azurerm_management_group.root.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "not": {
      "field": "location",
      "in": "[parameters('allowedLocations')]"
    }
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE

  parameters = <<PARAMETERS
{
  "allowedLocations": {
    "type": "Array",
    "metadata": {
      "displayName": "Allowed Locations",
      "description": "The list of allowed locations"
    },
    "defaultValue": ${jsonencode(var.allowed_locations)}
  }
}
PARAMETERS
}

# Require Tag (Environment)
resource "azurerm_policy_definition" "require_tag_environment" {
  name                = "require-tag-environment"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Require Environment Tag"
  description         = "Requires the Environment tag on all resources"
  management_group_id = data.azurerm_management_group.root.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "field": "tags['Environment']",
    "exists": "false"
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
}

# Require Tag (Owner)
resource "azurerm_policy_definition" "require_tag_owner" {
  name                = "require-tag-owner"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Require Owner Tag"
  description         = "Requires the Owner tag on all resources"
  management_group_id = data.azurerm_management_group.root.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "field": "tags['Owner']",
    "exists": "false"
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
}

# Require Tag (CostCenter)
resource "azurerm_policy_definition" "require_tag_costcenter" {
  name                = "require-tag-costcenter"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Require CostCenter Tag"
  description         = "Requires the CostCenter tag on all resources"
  management_group_id = data.azurerm_management_group.root.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "field": "tags['CostCenter']",
    "exists": "false"
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
}

# Require Tag (Project)
resource "azurerm_policy_definition" "require_tag_project" {
  name                = "require-tag-project"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Require Project Tag"
  description         = "Requires the Project tag on all resources"
  management_group_id = data.azurerm_management_group.root.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "field": "tags['Project']",
    "exists": "false"
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
}

# Audit Diagnostic Settings - Log Analytics Workspace
resource "azurerm_policy_definition" "audit_diagnostics_law" {
  name                = "audit-diagnostics-law"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "Audit Diagnostic Settings for Log Analytics"
  description         = "Audits diagnostic settings for resources to send to Log Analytics"
  management_group_id = data.azurerm_management_group.root.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "field": "type",
    "in": [
      "Microsoft.Network/networkSecurityGroups",
      "Microsoft.Network/applicationGateways",
      "Microsoft.Compute/virtualMachines",
      "Microsoft.KeyVault/vaults"
    ]
  },
  "then": {
    "effect": "auditIfNotExists",
    "details": {
      "type": "Microsoft.Insights/diagnosticSettings",
      "existenceCondition": {
        "allOf": [
          {
            "field": "Microsoft.Insights/diagnosticSettings/logs.enabled",
            "equals": "true"
          },
          {
            "field": "Microsoft.Insights/diagnosticSettings/workspaceId",
            "exists": "true"
          }
        ]
      }
    }
  }
}
POLICY_RULE
}