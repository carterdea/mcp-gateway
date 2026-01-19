FROM oven/bun:1-alpine

WORKDIR /app

# Install the Trello MCP server
RUN bun add -g @delorenj/mcp-server-trello

# Set environment variables (will be overridden by Docker Desktop)
ENV TRELLO_API_KEY=""
ENV TRELLO_TOKEN=""

# Docker MCP metadata label
LABEL io.docker.server.metadata='{"name":"trello","description":"Trello MCP server for board and card management","command":["bunx","-y","@delorenj/mcp-server-trello"],"env":[{"name":"TRELLO_API_KEY","value":"{{trello.api_key}}"},{"name":"TRELLO_TOKEN","value":"{{trello.token}}"}],"secrets":[{"name":"trello.api_key","env":"TRELLO_API_KEY","description":"Trello API key from https://trello.com/power-ups/admin"},{"name":"trello.token","env":"TRELLO_TOKEN","description":"Trello token from API key page"}]}'

ENTRYPOINT ["bunx", "-y", "@delorenj/mcp-server-trello"]
