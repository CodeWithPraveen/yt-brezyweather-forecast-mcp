# BrezyWeather forecast infrastructure

- Azure access goes through the `azure` MCP server only. It signs in as `sp-brezyweather-mcp-reader`, which holds Reader on `rg-brezyweather-forecast-mcp` and nothing else.
- Don't run `az` in the shell: that would use the engineer's own sign-in, not the reader identity.
- To list resource groups, use the `azure` server's `group_list` tool. For tags and settings, call its `arm` tool with the command `execute_query` and an Azure Resource Graph query in `parameters.query`.
- When a tool result is saved to a file, open it with the Read tool. Don't run Bash on it: no `grep`, no `python`.
- Name resources by name. Never print subscription, tenant, client, or object IDs, or full resource IDs.
- If Azure refuses an action, report the error code and the action it names. Don't look for another way to make the change.
