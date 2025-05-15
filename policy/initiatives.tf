# Policy Initiatives

# Security Baseline Initiative
resource "azurerm_policy_set_definition" "security_baseline" {
  name                = "security-baseline"
  policy_type         = "Custom"
  display_name        = "Security Baseline"
  description         = "Initiative containing security baseline policies"
  management_group_id = data.azurerm_management_group.root.id

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_public_ip.id
    reference_id         = "DenyPublicIP"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.allowed_locations.id
    reference_id         = "AllowedLocations"
    parameter_values     = <<VALUE
    {
      "allowedLocations": {"value": ${jsonencode(var.allowed_locations)}}
    }
    VALUE
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.audit_diagnostics_law.id
    reference_id         = "AuditDiagnostics"
  }

  # Reference built-in policy definitions
  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/f8456c1c-aa66-4dfb-861a-25d127b775c9" # Prevent usage of storage accounts with unrestricted network access
    reference_id         = "SecureStorageAccounts"
  }

  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a451c1ef-c6ca-483d-87ed-f49761e3ffb5" # CORS should not allow every resource to access your App Service
    reference_id         = "AppServiceCORS"
  }
}

# Tagging Compliance Initiative
resource "azurerm_policy_set_definition" "tagging_compliance" {
  name                = "tagging-compliance"
  policy_type         = "Custom"
  display_name        = "Tagging Compliance"
  description         = "Initiative to enforce consistent tagging across the organization"
  management_group_id = data.azurerm_management_group.root.id

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_tag_environment.id
    reference_id         = "RequireEnvironmentTag"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_tag_owner.id
    reference_id         = "RequireOwnerTag"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_tag_costcenter.id
    reference_id         = "RequireCostCenterTag"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_tag_project.id
    reference_id         = "RequireProjectTag"
  }
}