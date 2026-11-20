# BrezyWeather forecast: read-only Azure access for Claude Code

Claude Code reaches Azure through the Azure MCP Server, signed in as a service principal that holds only Reader on one resource group. Companion repo for the video *Give Your AI Agent Read-Only Azure Access with MCP*.

## Requirements

- Claude Code (tested with 2.1.328), Node.js LTS with `npx`, Azure CLI (tested with 2.89.0) signed in with rights to create an app registration and assign roles on the resource group.
- Cost is about zero: an empty storage account and a managed identity.

## Setup

Load the env file in every new shell before you start `claude`, or the server can't sign in.

```bash
az group create --name rg-brezyweather-forecast-mcp --location eastus2
az deployment group create --resource-group rg-brezyweather-forecast-mcp --template-file infra/main.bicep
./setup/new-reader-identity.sh                          # Reader on the group; writes ~/.brezyweather/mcp-reader.env
set -a; source ~/.brezyweather/mcp-reader.env; set +a    # load the reader's variables into this shell
claude mcp add --scope project \
  -e AZURE_TOKEN_CREDENTIALS=EnvironmentCredential \
  -e 'AZURE_TENANT_ID=${BW_READER_TENANT_ID}' \
  -e 'AZURE_CLIENT_ID=${BW_READER_CLIENT_ID}' \
  -e 'AZURE_CLIENT_SECRET=${BW_READER_CLIENT_SECRET}' \
  -e 'AZURE_SUBSCRIPTION_ID=${BW_SUBSCRIPTION_ID}' \
  --transport stdio azure -- npx -y @azure/mcp@3.0.0 server start   # writes .mcp.json, no secrets
claude mcp list                                         # azure should be the only Azure server
claude                                                  # approve the azure server when asked
```

If you installed the Azure plugin, its server signs in as you and loads next to this one. `.claude/settings.json` turns `azure@claude-plugins-official` off for this project; if `claude mcp list` still shows another Azure server, such as `plugin:azure:azure`, turn it off here with `claude plugin disable <plugin> --scope project`.

For day-to-day use, add `"--read-only"` after `"start"` in `.mcp.json` so the server offers no write tools. The Reader role is still what Azure enforces.

## Tear down

```bash
./setup/teardown.sh                  # service principal, role assignment, env file, Entra deleted items, the azure server in .mcp.json
DELETE_RG=yes ./setup/teardown.sh    # the same, plus the resource group
```
