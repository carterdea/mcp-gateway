FROM oven/bun:1-alpine

WORKDIR /app

# Install the Harvest MCP server
RUN bun add -g @standardbeagle/harvest-mcp

# Set environment variables (will be overridden by Docker Desktop)
ENV HARVEST_ACCOUNT_ID=""
ENV HARVEST_ACCESS_TOKEN=""

# Docker MCP metadata label
LABEL io.docker.server.metadata='{"name":"harvest","description":"Harvest MCP server for time tracking and project management","command":["bunx","-y","@standardbeagle/harvest-mcp"],"env":[{"name":"HARVEST_ACCOUNT_ID","value":"{{harvest.account_id}}"},{"name":"HARVEST_ACCESS_TOKEN","value":"{{harvest.access_token}}"}],"secrets":[{"name":"harvest.account_id","env":"HARVEST_ACCOUNT_ID","description":"Harvest Account ID"},{"name":"harvest.access_token","env":"HARVEST_ACCESS_TOKEN","description":"Harvest Access Token from https://id.getharvest.com/developers"}]}'

ENTRYPOINT ["bunx", "-y", "@standardbeagle/harvest-mcp"]
