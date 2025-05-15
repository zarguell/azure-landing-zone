provider "azurerm" {
  features {}
}

provider "azuread" {
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.0"
}

# Load variables
variable "location" {
  description = "The Azure Region where resources should be created"
  type        = string
  default     = "eastus"
}

variable "secondary_location" {
  description = "The secondary Azure Region for resources"
  type        = string
  default     = "westus"
}

variable "allowed_locations" {
  description = "List of allowed Azure Regions"
  type        = list(string)
  default     = ["eastus", "westus"]
}

variable "security_subscription_id" {
  description = "ID of the manually created security subscription"
  type        = string
}

variable "workload_subscription_ids" {
  description = "Map of workload subscription IDs"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Platform"
    Owner       = "Platform-Team"
    CostCenter  = "IT-Platform"
    Project     = "Landing-Zone"
  }
}

# Import existing subscriptions - these must be created manually in the Azure Portal
data "azurerm_subscription" "security" {
  subscription_id = var.security_subscription_id
}

locals {
  # Process workload subscriptions
  workload_subscriptions = {
    for k, v in var.workload_subscription_ids : k => {
      id   = v
      type = can(regex("^dev", k)) ? "Dev" : "Prod"
    }
  }
}