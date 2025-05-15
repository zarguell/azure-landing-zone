# Policy Assignments

# Assign Security Baseline to Root MG
resource "azurerm_management_group_policy_assignment" "security_baseline_root" {
  name                 = "security-baseline-root"
  policy_definition_id = azurerm_policy_set_definition.security_baseline.id
  management_group_id  = data.azurerm_management_group.root.id
  description          = "Assignment of the Security Baseline Initiative to the Root Management Group"
  display_name         = "Security Baseline"
  
  parameters = <<PARAMETERS
  {
    "allowedLocations": {"value": ${jsonencode(var.allowed_locations)}}
  }
  PARAMETERS
}

# Assign Tagging Compliance to Root MG
resource "azurerm_management_group_policy_assignment" "tagging_compliance_root" {
  name                 = "tagging-compliance-root"
  policy_definition_id = azurerm_policy_set_definition.tagging_compliance.id
  management_group_id  = data.azurerm_management_group.root.id
  description          = "Assignment of the Tagging Compliance Initiative to the Root Management Group"
  display_name         = "Tagging Compliance"
}

# Different security policies for Dev and Prod environments
# Dev Assignment - Less restrictive for Public IPs
resource "azurerm_policy_definition" "audit_public_ip" {
  name                = "audit-public-ip-creation"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "Audit creation of Public IPs"
  description         = "This policy audits the creation of Public IPs across the organization"
  management_group_id = data.azurerm_management_group.root.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "field": "type",
    "equals": "Microsoft.Network/publicIPAddresses"
  },
  "then": {
    "effect": "audit"
  }
}
POLICY_RULE
}

# Assign Public IP Audit Policy to Dev MG
resource "azurerm_management_group_policy_assignment" "audit_public_ip_dev" {
  name                 = "audit-public-ip-dev"
  policy_definition_id = azurerm_policy_definition.audit_public_ip.id
  management_group_id  = azurerm_management_group.dev.id
  description          = "Assignment of the Audit Public IP Policy to the Dev Management Group"
  display_name         = "Audit Public IP Creation"
}

# Assign Deny Public IP Policy to Prod MG
resource "azurerm_management_group_policy_assignment" "deny_public_ip_prod" {
  name                 = "deny-public-ip-prod"
  policy_definition_id = azurerm_policy_definition.deny_public_ip.id
  management_group_id  = azurerm_management_group.prod.id
  description          = "Assignment of the Deny Public IP Policy to the Prod Management Group"
  display_name         = "Deny Public IP Creation"
}

# Apply enhanced security settings to the Platform MG
resource "azurerm_policy_definition" "require_tls_storage" {
  name                = "require-tls-storage"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Storage accounts should only accept secure traffic"
  description         = "Audit requirement for Storage accounts to only accept secure traffic"
  management_group_id = data.azurerm_management_group.root.id

  policy_rule = <<POLICY_RULE
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Storage/storageAccounts"
      },
      {
        "field": "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly",
        "notEquals": true
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
}

# Assign TLS for Storage requirement to Platform MG
resource "azurerm_management_group_policy_assignment" "require_tls_storage_platform" {
  name                 = "require-tls-platform"
  policy_definition_id = azurerm_policy_definition.require_tls_storage.id
  management_group_id  = azurerm_management_group.platform.id
  description          = "Assignment of the TLS for Storage Policy to the Platform Management Group"
  display_name         = "Storage Accounts Must Use TLS"
}