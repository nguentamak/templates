# Fichier généré le Fri, Aug  8, 2025 11:04:43 PM
# NE PAS MODIFIER DIRECTEMENT

resource "azurerm_resource_group" "rg_prod_weu" {
  name     = "rg-prod-weu"
  location = "West Europe"
  tags = {
    Environment = "production"
    GeneratedBy = "shell-script"
  }
}

resource "azurerm_resource_group" "rg_dev_neu" {
  name     = "rg-dev-neu"
  location = "North Europe"
  tags = {
    Environment = "development"
    GeneratedBy = "shell-script"
  }
}
