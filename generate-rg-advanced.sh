#!/bin/bash

# Configurations multiples
declare -A RGS=(
  ["rg-prod-weu"]="West Europe:production"
  ["rg-dev-neu"]="North Europe:development"
)

# Entête du fichier
cat > resource_groups.tf <<EOF
# Fichier généré le $(date)
# NE PAS MODIFIER DIRECTEMENT
EOF

# Génération dynamique
for rg_name in "${!RGS[@]}"; do
  IFS=':' read -r location environment <<< "${RGS[$rg_name]}"
  
  cat >> resource_groups.tf <<EOF

resource "azurerm_resource_group" "${rg_name//-/_}" {
  name     = "$rg_name"
  location = "$location"
  tags = {
    Environment = "$environment"
    GeneratedBy = "shell-script"
  }
}
EOF
done

echo "Génération terminée. Vérifiez resource_groups.tf"