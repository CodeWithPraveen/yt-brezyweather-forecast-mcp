#!/usr/bin/env bash
# Creates the service principal the Azure MCP Server signs in as: Reader on one
# resource group, nothing else. Writes its credentials to an env file outside the
# repo (mode 600) and prints no secret.
set -euo pipefail

RG="${1:-rg-brezyweather-forecast-mcp}"
ENV_FILE="${2:-$HOME/.brezyweather/mcp-reader.env}"
SP_NAME="sp-brezyweather-mcp-reader"

if [ -n "$(az ad app list --display-name "$SP_NAME" --query '[].appId' -o tsv)" ]; then
  echo "$SP_NAME already exists. Run setup/teardown.sh first." >&2
  exit 1
fi

SUB_ID="$(az account show --query id -o tsv)"
SCOPE="$(az group show --name "$RG" --query id -o tsv)"

# az prints a credentials warning on stderr; keep it in a log and show it only on failure.
ERR_LOG="$(mktemp)"
trap 'rm -f "$ERR_LOG"' EXIT
if ! CREDS="$(az ad sp create-for-rbac --name "$SP_NAME" --role Reader --scopes "$SCOPE" \
    --query '[appId, tenant, password]' -o tsv 2>"$ERR_LOG")"; then
  cat "$ERR_LOG" >&2
  echo "Creating $SP_NAME failed. Run setup/teardown.sh to remove anything half-created." >&2
  exit 1
fi
{ read -r APP_ID; read -r TENANT_ID; read -r SECRET; } <<< "$CREDS" || true
if [ -z "${APP_ID:-}" ] || [ -z "${TENANT_ID:-}" ] || [ -z "${SECRET:-}" ]; then
  cat "$ERR_LOG" >&2
  echo "az returned no credentials for $SP_NAME. Run setup/teardown.sh, then try again." >&2
  exit 1
fi

umask 077
mkdir -p "$(dirname "$ENV_FILE")"
printf 'BW_READER_TENANT_ID=%s\nBW_READER_CLIENT_ID=%s\nBW_READER_CLIENT_SECRET=%s\nBW_SUBSCRIPTION_ID=%s\n' \
  "$TENANT_ID" "$APP_ID" "$SECRET" "$SUB_ID" > "$ENV_FILE"

echo "Created $SP_NAME with Reader on $RG."
echo "Credentials written to $ENV_FILE. Load them before you start Claude Code:"
echo "  set -a; source $ENV_FILE; set +a"
