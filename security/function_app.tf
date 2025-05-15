# Resources for the centralized security tooling

# Create a resource group for security resources
resource "azurerm_resource_group" "security" {
  name     = "sec-rg-${var.location}-central"
  location = var.location
  tags     = merge(var.tags, {
    Environment = "Platform"
    Project     = "Security"
  })
  provider = azurerm.security_subscription
}

# Log Analytics Workspace for centralized logging
resource "azurerm_log_analytics_workspace" "central" {
  name                = "sec-law-${var.location}-central"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  sku                 = "PerGB2018" # Free tier compatible
  retention_in_days   = 30          # Minimum for free tier
  tags                = azurerm_resource_group.security.tags
  provider            = azurerm.security_subscription
}

# Storage account for the function app
resource "azurerm_storage_account" "security_func" {
  name                     = "secfuncstorage${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.security.name
  location                 = azurerm_resource_group.security.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = azurerm_resource_group.security.tags
  provider                 = azurerm.security_subscription
}

# Random string for storage account name
resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

# App Service Plan for function app - Free tier F1
resource "azurerm_service_plan" "security_func" {
  name                = "sec-plan-${var.location}-scan"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  os_type             = "Windows"
  sku_name            = "F1"
  tags                = azurerm_resource_group.security.tags
  provider            = azurerm.security_subscription
}

# Function App for security scanning
resource "azurerm_windows_function_app" "security_scan" {
  name                       = "sec-func-${var.location}-scan"
  location                   = azurerm_resource_group.security.location
  resource_group_name        = azurerm_resource_group.security.name
  service_plan_id            = azurerm_service_plan.security_func.id
  storage_account_name       = azurerm_storage_account.security_func.name
  storage_account_access_key = azurerm_storage_account.security_func.primary_access_key
  tags                       = azurerm_resource_group.security.tags
  provider                   = azurerm.security_subscription

  site_config {
    application_stack {
      powershell_core_version = "7.2"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "powershell"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.security_func.instrumentation_key
    "TENANT_ID"                      = data.azurerm_client_config.current.tenant_id
    "LOG_ANALYTICS_WORKSPACE_ID"     = azurerm_log_analytics_workspace.central.id
  }
}

# Application Insights for Function App monitoring
resource "azurerm_application_insights" "security_func" {
  name                = "sec-ai-${var.location}-scan"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  application_type    = "web"
  tags                = azurerm_resource_group.security.tags
  provider            = azurerm.security_subscription
}

# Function code - Deploy a basic PowerShell function for scanning resources
# In a real implementation, this would be a more complex function
resource "azurerm_function_app_function" "scan_resources" {
  name            = "ScanResources"
  function_app_id = azurerm_windows_function_app.security_scan.id
  language        = "PowerShell"
  file {
    name    = "run.ps1"
    content = <<EOF
# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

# Authenticate to Azure (using managed identity)
try {
    Connect-AzAccount -Identity
    
    # Get all subscriptions
    $subscriptions = Get-AzSubscription
    
    foreach ($subscription in $subscriptions) {
        Set-AzContext -Subscription $subscription.Id
        
        # Scan for common security issues
        $resources = Get-AzResource
        
        # Example check: Find storage accounts with public access enabled
        $storageAccounts = $resources | Where-Object { $_.ResourceType -eq "Microsoft.Storage/storageAccounts" }
        foreach ($storage in $storageAccounts) {
            $storageAccount = Get-AzStorageAccount -ResourceGroupName $storage.ResourceGroupName -Name $storage.Name
            if ($storageAccount.AllowBlobPublicAccess -eq $true) {
                Write-Host "WARNING: Storage account $($storage.Name) in subscription $($subscription.Name) has public access enabled"
                
                # Log to Log Analytics
                $logData = @{
                    "SubscriptionId" = $subscription.Id
                    "SubscriptionName" = $subscription.Name
                    "ResourceGroup" = $storage.ResourceGroupName
                    "ResourceName" = $storage.Name
                    "ResourceType" = $storage.ResourceType
                    "IssueType" = "Public Storage Access"
                    "Severity" = "High"
                    "ScanTime" = $currentUTCtime
                }
                
                # In a real implementation, you would send this to Log Analytics
                # Send-LogAnalyticsData -CustomerId $env:LOG_ANALYTICS_WORKSPACE_ID -SharedKey $env:LOG_ANALYTICS_WORKSPACE_KEY -Body $logData -LogType "SecurityScan"
            }
        }
    }
} catch {
    Write-Host "Error scanning resources: $_"
}
EOF
  }
  config_json = jsonencode({
    "bindings" = [
      {
        "name"     = "Timer"
        "type"     = "timerTrigger"
        "direction" = "in"
        "schedule" = "0 0 0 * * *" # Run daily at midnight
      }
    ]
  })
  
  provider = azurerm.security_subscription
}

# Create an alert rule based on security scan results
resource "azurerm_monitor_scheduled_query_rules_alert" "security_issues" {
  name                = "sec-alert-${var.location}-security-issues"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  provider            = azurerm.security_subscription

  action {
    action_group           = [azurerm_monitor_action_group.security_alerts.id]
    email_subject          = "Security Issue Detected"
  }

  data_source_id = azurerm_log_analytics_workspace.central.id
  description    = "Alert when security issues are detected by the daily scan"
  enabled        = true
  
  query       = <<-QUERY
    SecurityScan_CL
    | where Severity_s == "High"
    | project SubscriptionName_s, ResourceName_s, ResourceType_s, IssueType_s, Severity_s, ScanTime_t
  QUERY
  severity    = 1
  frequency   = 1440 # Daily in minutes
  time_window = 1440 # Look back 1 day
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  tags = azurerm_resource_group.security.tags
}

# Action group for security alerts
resource "azurerm_monitor_action_group" "security_alerts" {
  name                = "sec-ag-${var.location}-security-alerts"
  resource_group_name = azurerm_resource_group.security.name
  short_name          = "SecAlerts"
  provider            = azurerm.security_subscription

  # In a real implementation, you would configure email, SMS, etc.
  email_receiver {
    name                    = "SecurityTeamEmail"
    email_address           = "securityteam@example.com"
    use_common_alert_schema = true
  }
}