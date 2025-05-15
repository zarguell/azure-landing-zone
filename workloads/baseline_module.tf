# Reusable module for new workload subscriptions
# This module can be used to apply baseline configurations to new workload subscriptions

# Resource Group for baseline resources
resource "azurerm_resource_group" "baseline" {
  name     = "${var.environment}-rg-${var.location}-baseline"
  location = var.location
  tags     = var.tags
}

# Diagnostic setting to forward logs to central workspace
resource "azurerm_monitor_diagnostic_setting" "subscription" {
  name                       = "send-to-central-logs"
  target_resource_id         = "/subscriptions/${var.subscription_id}"
  log_analytics_workspace_id = var.central_log_analytics_id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "ServiceHealth"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Recommendation"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Autoscale"
  }

  enabled_log {
    category = "ResourceHealth"
  }
}

# Azure Security Center - Standard Tier is not Free, so configure with Free Tier
resource "azurerm_security_center_subscription_pricing" "sct_free" {
  for_each = toset([
    "VirtualMachines",   # These are the resource types that
    "StorageAccounts",   # have a Free tier option in
    "AppServices",       # Azure Defender/Security Center
    "SqlServers",
    "KeyVaults"
  ])
  
  tier          = "Free"
  resource_type = each.key
}

# Configure Security Center to send alerts and recommendations to central workspace
resource "azurerm_security_center_workspace" "central" {
  scope        = "/subscriptions/${var.subscription_id}"
  workspace_id = var.central_log_analytics_id
}

# Configure basic network for workload
resource "azurerm_virtual_network" "baseline" {
  name                = "${var.environment}-vnet-${var.location}-baseline"
  location            = azurerm_resource_group.baseline.location
  resource_group_name = azurerm_resource_group.baseline.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.baseline.name
  virtual_network_name = azurerm_virtual_network.baseline.name
  address_prefixes     = ["10.0.0.0/24"]
}

# NSG with baseline security rules
resource "azurerm_network_security_group" "baseline" {
  name                = "${var.environment}-nsg-${var.location}-baseline"
  location            = azurerm_resource_group.baseline.location
  resource_group_name = azurerm_resource_group.baseline.name
  tags                = var.tags

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "baseline" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.baseline.id
}

# Variables for the baseline module
variable "subscription_id" {
  description = "ID of the subscription to apply baseline configurations to"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable "central_log_analytics_id" {
  description = "ID of the central Log Analytics workspace"
  type        = string
}

# Outputs
output "resource_group_id" {
  value = azurerm_resource_group.baseline.id
}

output "virtual_network_id" {
  value = azurerm_virtual_network.baseline.id
}

output "subnet_id" {
  value = azurerm_subnet.default.id
}