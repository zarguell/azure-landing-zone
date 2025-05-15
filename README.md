# Azure Landing Zone - Terraform Configuration

This repository contains the Terraform code needed to deploy a Free Tier compliant Azure Landing Zone based on the requirements specification. The landing zone includes management groups, policy definitions and assignments, security tooling, and workload baseline configurations.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0+)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (latest version)
- Active Azure subscription(s)
- Permissions to create resources at the tenant level (Management Groups, Policy definitions)

## 📂 Repository Structure

```
landing-zone/
├── main.tf                 # Main configuration file
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── mg_structure.tf         # Management Groups and RBAC
├── policy/
│   ├── policy_definitions.tf
│   ├── initiatives.tf
│   └── assignments.tf
├── security/
│   ├── function_app.tf     # Security scanning function
│   └── lighthouse.tf       # Lighthouse delegations
└── workloads/
    └── baseline_module.tf  # Reusable module for new subscriptions
```

## 🚀 Deployment Steps

### 1. Prepare Azure Subscriptions (Manual)

Because of the Azure Free Tier compliance requirement, you must create subscriptions manually via the Azure Portal:

1. Create a subscription for security & platform services
2. Create subscriptions for each workload as needed (Dev/Prod)

### 2. Prepare Azure AD Groups (Manual)

Create the following Azure AD Groups:
- PlatformAdmins
- SecurityAuditors
- WorkloadOwners

### 3. Configure Terraform Variables

Create a `terraform.tfvars` file with your specific values:

```hcl
security_subscription_id = "00000000-0000-0000-0000-000000000000"

workload_subscription_ids = {
  "dev-project1" = "11111111-1111-1111-1111-111111111111"
  "prod-project1" = "22222222-2222-2222-2222-222222222222"
}

location = "eastus"
secondary_location = "westus"
allowed_locations = ["eastus", "westus"]
```

### 4. Initialize and Apply Terraform

```bash
# Login to Azure
az login

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -out=tfplan

# Apply the deployment
terraform apply tfplan
```

## 🧩 Adding New Workload Subscriptions

1. Create a new subscription via the Azure Portal
2. Add the subscription ID to your `terraform.tfvars` file:

```hcl
workload_subscription_ids = {
  "dev-project1" = "11111111-1111-1111-1111-111111111111"
  "prod-project1" = "22222222-2222-2222-2222-222222222222"
  "dev-project2" = "33333333-3333-3333-3333-333333333333"  # New subscription
}
```

3. Apply the Terraform configuration:

```bash
terraform apply
```

## 📊 Monitoring Policy Compliance

1. Navigate to the Azure Portal
2. Go to "Policy" > "Compliance"
3. Filter by Management Group or Subscription
4. View compliance status for assigned policies

## 🔐 Security Features

This landing zone includes the following security features:

- Management Group hierarchy for governance
- Policy definitions for security baseline
- Centralized logging with Log Analytics
- Daily security scanning with Azure Functions
- Azure Lighthouse delegations for central monitoring
- Baseline NSG with deny all inbound rule
- Policy enforced tagging system

## 📝 Notes

- All resources are deployed using Azure Free Tier compatible options
- Subscription creation is manual due to Free Tier constraints
- Management Group structure follows the requirements specification
- RBAC is configured via built-in and custom roles
- Policies include both audit and deny effects
- Security scanning uses PowerShell Azure Functions

## 📘 Terraform Outputs

After applying the Terraform configuration, you'll receive the following outputs:

- Management Group IDs and names
- Policy Initiatives and Assignments
- Security Function App URL
- Central Log Analytics Workspace ID
- Azure AD Group names (for reference)
- Workload Baseline resources