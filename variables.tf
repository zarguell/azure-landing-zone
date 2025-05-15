# Variables for the landing zone

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
  description = "Map of workload subscription IDs (name = subscription_id)"
  type        = map(string)
  default     = {}
  
  # Example:
  # workload_subscription_ids = {
  #   "dev-project1" = "00000000-0000-0000-0000-000000000000"
  #   "prod-project1" = "11111111-1111-1111-1111-111111111111"
  # }
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

variable "enable_security_center_free" {
  description = "Enable Security Center free tier"
  type        = bool
  default     = true
}

variable "enable_lighthouse" {
  description = "Enable Azure Lighthouse delegations"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics"
  type        = number
  default     = 30  # Free tier minimum
}

variable "security_scan_schedule" {
  description = "Schedule for the security scan function in CRON format"
  type        = string
  default     = "0 0 0 * * *"  # Daily at midnight
}