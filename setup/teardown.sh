#!/usr/bin/env bash
# Removes the reader service principal, its role assignment, its env file, and the
# azure server in this repo's .mcp.json, and purges the service principal from Entra's
# deleted items. DELETE_RG=yes also deletes the resource group.
set -euo pipefail

RG="${1:-rg-brezyweather-forecast-mcp}"
ENV_FILE="${2:-$HOME/.brezyweather/mcp-reader.env}"
SP_NAME="sp-brezyweather-mcp-reader"
GRAPH="https://graph.microsoft.com/v1.0"

for APP_ID in $(az ad app list --display-name "$SP_NAME" --query '[].appId' -o tsv); do
  az role assignment delete --assignee "$APP_ID" --resource-group "$RG" || true
  az ad app delete --id "$APP_ID"
  echo "Deleted $SP_NAME and its role assignment."
done

for TYPE in application servicePrincipal; do
  for DELETED_ID in $(az rest --method GET \
      --url "$GRAPH/directory/deletedItems/microsoft.graph.$TYPE?\$filter=displayName eq '$SP_NAME'" \
      --query 'value[].id' -o tsv); do
    az rest --method DELETE --url "$GRAPH/directory/deletedItems/$DELETED_ID"
    echo "Purged the deleted $TYPE $SP_NAME."
  done
done

rm -f "$ENV_FILE"

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "$REPO_DIR/.mcp.json" ] && grep -q '"azure"' "$REPO_DIR/.mcp.json"; then
  (cd "$REPO_DIR" && claude mcp remove --scope project azure >/dev/null)
  if tr -d ' \n' < "$REPO_DIR/.mcp.json" | grep -qx '{"mcpServers":{}}'; then
    rm -f "$REPO_DIR/.mcp.json"
  fi
  echo "Removed the azure server from .mcp.json."
fi

if [ "${DELETE_RG:-no}" = "yes" ]; then
  az group delete --name "$RG" --yes --no-wait
  echo "Deleting $RG."
fi
