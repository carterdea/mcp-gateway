FROM oven/bun:1

WORKDIR /app

# Install mcp-aggregator using bun
# Note: If mcp-aggregator proves incompatible with Bun, switch to node:18-alpine base
RUN bun add -g @mcp/aggregator

# Install supergateway using bun
RUN bun add -g supergateway

# Copy configuration
COPY mcp-config.json /app/mcp-config.json

ENV PORT=8080
ENV MCP_CONFIG=/app/mcp-config.json
ENV MCP_LOG_LEVEL=info

EXPOSE 8080

# Start Supergateway wrapping mcp-aggregator
CMD ["supergateway", "--port", "8080", "--stdio", "mcp-aggregator"]
