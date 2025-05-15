# Provider configuration for different subscriptions
# This allows us to deploy resources to different subscriptions in the same Terraform configuration

provider "azurerm" {
  alias           = "security_subscription"
  subscription_id = var.security_subscription_id
  
  features {}
}

# Module instantiation for workload subscriptions
# This creates a module instance for each workload subscription

module "workload_baseline" {
  for_each = local.workload_subscriptions
  
  source = "./workloads"
  
  subscription_id        = each.value.id
  environment            = each.value.type
  location               = var.location
  central_log_analytics_id = azurerm_log_analytics_workspace.central.id
  tags = {
    Environment = each.value.type
    Owner       = "Workload-Owner"
    CostCenter  = "IT-1000"
    Project     = each.key
  }
  
  # Provider configuration for the workload subscription
  providers = {
    azurerm = azurerm.${each.key}_subscription
  }
}

# Create a provider for each workload subscription dynamically
# This is a bit complex but necessary to deploy to multiple subscriptions
# In real world, you might use different approaches like separate Terraform workspaces
locals {
  workload_providers = {
    for k, v in local.workload_subscriptions : k => <<-EOT
      provider "azurerm" {
        alias           = "${k}_subscription"
        subscription_id = "${v.id}"
        
        features {}
      }
    EOT
  }
}

# Output providers to a file that can be included via terraform -var-file
resource "local_file" "providers" {
  filename = "${path.module}/providers.tf"
  content  = join("\n", values(local.workload_providers))
}

# Outputs
output "management_groups" {
  description = "Management group IDs and names"
  value = {
    root     = data.azurerm_management_group.root.name
    platform = azurerm_management_group.platform.name
    workloads = azurerm_management_group.workloads.name
    dev      = azurerm_management_group.dev.name
    prod     = azurerm_management_group.prod.name
  }
}

output "policy_initiatives" {
  description = "Policy initiatives created"
  value = {
    security_baseline = azurerm_policy_set_definition.security_baseline.id
    tagging_compliance = azurerm_policy_set_definition.tagging_compliance.id
  }
}

output "policy_assignments" {
  description = "Policy assignments by scope"
  value = {
    root = {
      security_baseline = azurerm_management_group_policy_assignment.security_baseline_root.id
      tagging_compliance = azurerm_management_group_policy_assignment.tagging_compliance_root.id
    }
    dev = {
      audit_public_ip = azurerm_management_group_policy_assignment.audit_public_ip_dev.id
    }
    prod = {
      deny_public_ip = azurerm_management_group_policy_assignment.deny_public_ip_prod.id
    }
    platform = {
      require_tls_storage = azurerm_management_group_policy_assignment.require_tls_storage_platform.id
    }
  }
}

output "security_function_app_url" {
  description = "URL for the security scanning function app"
  value = azurerm_windows_function_app.security_scan.default_hostname
}

output "central_log_analytics_id" {
  description = "ID of the central Log Analytics workspace"
  value = azurerm_log_analytics_workspace.central.id
}

output "aad_groups" {
  description = "AAD group names (to be created manually)"
  value = {
    platform_admins = "PlatformAdmins"
    security_auditors = "SecurityAuditors"
    workload_owners = "WorkloadOwners"
  }
}

output "workload_baselines" {
  description = "Resources created in each workload subscription"
  value = {
    for k, v in module.workload_baseline : k => {
      resource_group_id = v.resource_group_id
      virtual_network_id = v.virtual_network_id
      subnet_id = v.subnet_id
    }
  }
}