#!/bin/bash

# Configuration
OUTPUT_FILE="resource_groups.tf"
RG_NAME="rg-prod-shell"
RG_LOCATION="West Europe"
RG_ENVIRONMENT="production"

# Génération du fichier Terraform
cat > $OUTPUT_FILE <<EOF
# Fichier généré automatiquement - $(date)
resource "azurerm_resource_group" "${RG_NAME//-/_}" {
  name     = "$RG_NAME"
  location = "$RG_LOCATION"
  tags = {
    Environment = "$RG_ENVIRONMENT"
    GeneratedBy = "shell-script"
  }
}
EOF

echo "Fichier $OUTPUT_FILE généré avec succès!"