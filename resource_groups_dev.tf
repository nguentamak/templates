# Généré le Sat, Aug  9, 2025  8:11:24 AM avec les paramètres suivants:
# Préfixe: rg, Env: dev, Région: westeurope
# Criticité: Medium, Owner: devops@company.com
# Diagnostics: Activés
resource "azurerm_resource_group" "rg_dev_westeurope_001" {
  name     = "rg-dev-westeurope-001"
  location = "westeurope"
  tags = {
    Environment  = "dev"
    Criticality = "Medium"
    Owner       = "devops@company.com"
    CostCenter  = "IT-000"
    ManagedBy   = "Terraform"
    Deployment  = "2025-08-09"
  }

  lifecycle {
    precondition {
      condition     = can(regex("^[a-z0-9-]{3,60}$", "rg-dev-westeurope-001"))
      error_message = "Format de nom invalide"
    }
  }
}

