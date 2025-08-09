#!/bin/bash
# generate-azure-rg-with-diag.sh - Génération avec diagnostics pour production

set -euo pipefail

# --------------------------
# CONFIGURATION PAR DÉFAUT
# --------------------------
DEFAULT_PREFIX="rg"
DEFAULT_ENV="dev"
DEFAULT_REGION="westeurope"
DEFAULT_CRITICALITY="Medium"
DEFAULT_OWNER="devops@company.com"
DEFAULT_COST_CENTER="IT-000"
DEFAULT_DIAG_STORAGE="/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/logging-rg/providers/Microsoft.Storage/storageAccounts/diagstorage"
DEFAULT_ADD_DIAG="true"  # Active les diagnostics pour prod par défaut

# --------------------------
# FONCTIONS
# --------------------------
show_help() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -p, --prefix          Préfixe des RG (défaut: $DEFAULT_PREFIX)"
  echo "  -e, --env             Environnement (défaut: $DEFAULT_ENV)"
  echo "  -r, --region          Région Azure (défaut: '$DEFAULT_REGION')"
  echo "  -c, --criticality     Criticité (défaut: $DEFAULT_CRITICALITY)"
  echo "  -o, --owner           Propriétaire (défaut: $DEFAULT_OWNER)"
  echo "  -cc, --cost-center    Centre de coût (défaut: $DEFAULT_COST_CENTER)"
  echo "  -s, --suffix          Suffixe numérique (défaut: 001)"
  echo "  -d, --diagnostics     ID Storage Account diagnostics (défaut: $DEFAULT_DIAG_STORAGE)"
  echo "  --no-diag             Désactive les diagnostics pour production"
  echo "  -n, --num-rg          Nombre de RG à générer (défaut: 1)"
  echo "  -h, --help            Affiche cette aide"
  exit 0
}

validate_input() {
  if ! az account list-locations --query "[?name=='$REGION'].name" -o tsv | grep -q "$REGION"; then
    echo "ERREUR: Région Azure invalide: $REGION" >&2
    exit 1
  fi
}

generate_rg_block() {
  local rg_name="$1"
  cat <<EOF >> "$OUTPUT_FILE"
resource "azurerm_resource_group" "${rg_name//-/_}" {
  name     = "$rg_name"
  location = "$REGION"
  tags = {
    Environment  = "$ENV"
    Criticality = "$CRITICALITY"
    Owner       = "$OWNER"
    CostCenter  = "$COST_CENTER"
    ManagedBy   = "Terraform"
    Deployment  = "$(date +%Y-%m-%d)"
  }

  lifecycle {
    precondition {
      condition     = can(regex("^[a-z0-9-]{3,60}\$", "$rg_name"))
      error_message = "Format de nom invalide"
    }
  }
}

EOF
}

generate_diagnostic_settings() {
  local rg_name="$1"
  cat <<EOF >> "$OUTPUT_FILE"
resource "azurerm_monitor_diagnostic_setting" "diag_${rg_name//-/_}" {
  name               = "diag-$rg_name"
  target_resource_id = azurerm_resource_group.${rg_name//-/_}.id
  storage_account_id = "$DIAG_STORAGE"

  log {
    category = "AuditEvent"
    enabled  = true

    retention_policy {
      days    = 90
      enabled = true
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      days    = 90
      enabled = true
    }
  }
}

EOF
}

# --------------------------
# PARAMÈTRES
# --------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--prefix)
      PREFIX="$2"
      shift 2
      ;;
    -e|--env)
      ENV="$2"
      shift 2
      ;;
    -r|--region)
      REGION="$2"
      shift 2
      ;;
    -c|--criticality)
      CRITICALITY="$2"
      shift 2
      ;;
    -o|--owner)
      OWNER="$2"
      shift 2
      ;;
    -cc|--cost-center)
      COST_CENTER="$2"
      shift 2
      ;;
    -s|--suffix)
      SUFFIX="$2"
      shift 2
      ;;
    -d|--diagnostics)
      DIAG_STORAGE="$2"
      shift 2
      ;;
    --no-diag)
      ADD_DIAG="false"
      shift
      ;;
    -n|--num-rg)
      NUM_RG="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo "Option invalide: $1" >&2
      exit 1
      ;;
  esac
done

# Application des valeurs par défaut
: ${PREFIX:="$DEFAULT_PREFIX"}
: ${ENV:="$DEFAULT_ENV"}
: ${REGION:="$DEFAULT_REGION"}
: ${CRITICALITY:="$DEFAULT_CRITICALITY"}
: ${OWNER:="$DEFAULT_OWNER"}
: ${COST_CENTER:="$DEFAULT_COST_CENTER"}
: ${SUFFIX:="001"}
: ${DIAG_STORAGE:="$DEFAULT_DIAG_STORAGE"}
: ${ADD_DIAG:="$DEFAULT_ADD_DIAG"}
: ${NUM_RG:=1}

# --------------------------
# GÉNÉRATION
# --------------------------
OUTPUT_FILE="resource_groups_${ENV}.tf"
echo "# Généré le $(date) avec les paramètres suivants:" > "$OUTPUT_FILE"
echo "# Préfixe: $PREFIX, Env: $ENV, Région: $REGION" >> "$OUTPUT_FILE"
echo "# Criticité: $CRITICALITY, Owner: $OWNER" >> "$OUTPUT_FILE"
echo "# Diagnostics: $([ "$ADD_DIAG" = "true" ] && echo "Activés" || echo "Désactivés")" >> "$OUTPUT_FILE"

validate_input

for ((i=0; i<NUM_RG; i++)); do
  RG_NAME="${PREFIX}-${ENV}-${REGION// /}-$(printf "%03d" $((SUFFIX + i)))"
  generate_rg_block "$RG_NAME"
  
  # Ajout des diagnostics si environnement prod et option activée
  if [[ "$ENV" == "prod" && "$ADD_DIAG" == "true" ]]; then
    generate_diagnostic_settings "$RG_NAME"
  fi
done

# --------------------------
# SORTIE
# --------------------------
echo -e "\n\033[1;32mFichier généré :\033[0m $OUTPUT_FILE"
echo -e "\n\033[1;34mExemples d'utilisation :\033[0m"
echo "# Production avec diagnostics:"
echo "$0 -e prod -r 'northeurope' -c High -d /subscriptions/.../storageAccounts/diagprod"
echo
echo "# Dev sans diagnostics:"
echo "$0 -e dev --no-diag"
echo
echo "# Multiple RGs:"
echo "$0 -n 3 -s 100 -e staging"