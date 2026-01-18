# MCP Gateway

Model Context Protocol (MCP) gateway deployed on Fly.io using mcp-aggregator and Supergateway to expose multiple stdio-based MCP servers via a single SSE endpoint for use with Poke.com and other MCP clients.

## Overview

This gateway aggregates multiple local MCP servers (stdio transport) and exposes them to remote clients via a single SSE endpoint. This enables AI assistants like Poke to interact with various services and tools through a unified interface.

## Current Deployment

- **MCP Servers**: 3 aggregated servers
  - Trello (`@delorenj/mcp-server-trello`)
  - Harvest (`@standardbeagle/harvest-mcp`)
  - Shopify (`@ajackus/shopify-mcp-server`)
- **Aggregator**: [mcp-aggregator](https://github.com/dwillitzer/mcp-aggregator) (combines multiple MCP servers into single stdio stream)
- **Gateway**: [Supergateway](https://github.com/hannesrudolph/supergateway) (stdio to SSE adapter)
- **Runtime**: Bun
- **Platform**: Fly.io (iad region)
- **Resources**: 1GB RAM, 1 shared vCPU

### SSE Endpoint

```
https://carterdea-mcp-gateway.fly.dev/sse
```

Use this URL in Poke.com's MCP integration settings to access all 3 MCP servers.

## Architecture

```
Poke.com (MCP Client)
    ↓ SSE
Supergateway (stdio → SSE adapter)
    ↓ stdio
mcp-aggregator (combines 3 MCPs)
    ↓ ↓ ↓
    Trello | Harvest | Shopify
        ↓      ↓        ↓
    REST APIs (external services)
```

## Prerequisites

- [Fly.io CLI](https://fly.io/docs/hands-on/install-flyctl/)
- [Bun](https://bun.sh/) (for local testing)
- MCP server credentials:
  - Trello API Key + Token
  - Harvest Account ID + Personal Access Token
  - Shopify Shop URL + Admin API Token

## Setup

### 1. Clone Repository

```bash
git clone <repo-url>
cd mcp-gateway
```

### 2. Configure MCP Server Credentials

#### Trello

Get your credentials:
- **API Key**: https://trello.com/app-key
- **Token**: Use the authorization URL from the API key page

Set as Fly secrets:

```bash
fly secrets set \
  TRELLO_API_KEY="your_api_key" \
  TRELLO_TOKEN="your_token" \
  --app carterdea-mcp-gateway
```

#### Harvest

Get your credentials:
- **Account ID**: Your Harvest account ID
- **Personal Access Token**: Create at https://id.getharvest.com/developers

Set as Fly secrets:

```bash
fly secrets set \
  HARVEST_ACCOUNT_ID="your_account_id" \
  HARVEST_ACCESS_TOKEN="your_access_token" \
  --app carterdea-mcp-gateway
```

#### Shopify

Get your credentials:
- **Shop URL**: e.g., `mystore.myshopify.com`
- **Admin API Token**: Create a custom app in your Shopify admin

Set as Fly secrets:

```bash
fly secrets set \
  SHOPIFY_SHOP_URL="mystore.myshopify.com" \
  SHOPIFY_ADMIN_API_TOKEN="shpat_..." \
  --app carterdea-mcp-gateway
```

#### All Secrets at Once

```bash
fly secrets set \
  TRELLO_API_KEY="..." \
  TRELLO_TOKEN="..." \
  HARVEST_ACCOUNT_ID="..." \
  HARVEST_ACCESS_TOKEN="..." \
  SHOPIFY_SHOP_URL="mystore.myshopify.com" \
  SHOPIFY_ADMIN_API_TOKEN="shpat_..." \
  --app carterdea-mcp-gateway
```

For local development, create `.env`:

```bash
TRELLO_API_KEY=your_api_key
TRELLO_TOKEN=your_token
HARVEST_ACCOUNT_ID=your_account_id
HARVEST_ACCESS_TOKEN=your_access_token
SHOPIFY_SHOP_URL=mystore.myshopify.com
SHOPIFY_ADMIN_API_TOKEN=shpat_...
```

### 3. Deploy to Fly.io

```bash
fly deploy
```

### 4. Verify Deployment

```bash
fly status --app carterdea-mcp-gateway
fly logs --app carterdea-mcp-gateway
```

## Configuration

### mcp-config.json

MCP servers are configured in `mcp-config.json`:

```json
{
  "servers": {
    "trello": {
      "enabled": true,
      "command": "bunx",
      "args": ["-y", "@delorenj/mcp-server-trello"],
      "env": {
        "TRELLO_API_KEY": "${TRELLO_API_KEY}",
        "TRELLO_TOKEN": "${TRELLO_TOKEN}"
      }
    },
    "harvest": {
      "enabled": true,
      "command": "bunx",
      "args": ["-y", "@standardbeagle/harvest-mcp"],
      "env": {
        "HARVEST_ACCOUNT_ID": "${HARVEST_ACCOUNT_ID}",
        "HARVEST_ACCESS_TOKEN": "${HARVEST_ACCESS_TOKEN}"
      }
    },
    "shopify": {
      "enabled": true,
      "command": "bunx",
      "args": ["-y", "@ajackus/shopify-mcp-server"],
      "env": {
        "SHOPIFY_SHOP_URL": "${SHOPIFY_SHOP_URL}",
        "SHOPIFY_ADMIN_API_TOKEN": "${SHOPIFY_ADMIN_API_TOKEN}"
      }
    }
  }
}
```

To disable an MCP server, set `"enabled": false`.

### Scaling

If health checks fail or the server is under-powered:

```bash
# Scale memory
fly scale memory 1024 --app carterdea-mcp-gateway

# Scale to 2 machines for redundancy
fly scale count 2 --app carterdea-mcp-gateway
```

### Machine Specs

Current configuration in `fly.toml`:
- Port: 8080
- Memory: 1GB RAM
- CPUs: 1 shared vCPU
- Auto-start: Enabled
- Auto-stop: Disabled
- Health check: `/sse` endpoint every 30s (10s timeout, 30s grace period)

## Future MCP Integrations

### Planned (Phase 2)

- [ ] **GitHub MCP** - Repository management, issues, PRs
- [ ] **Playwright MCP** - Browser automation for web testing

### Potential Future Additions

- [ ] **Graphite MCP** - Stacked PRs integration (`gt` CLI on server)
- [ ] **Apple Reminders/Notes MCP** - Sync reminders and notes from Apple ecosystem

### Adding More MCPs

To add more MCP servers:

1. Add server configuration to `mcp-config.json`
2. Set required environment variables as Fly secrets
3. Redeploy: `fly deploy`
4. Verify: `fly logs --app carterdea-mcp-gateway`

The mcp-aggregator automatically combines all enabled servers into a single stdio stream.

## Costs

- **Current**: ~$10-15/month on Fly.io (1GB machine)
- **Estimated with 5 MCPs**: $15-20/month (may need to scale to 2GB)

## Troubleshooting

### Health Checks Failing

```bash
# Check machine status
fly machine status <machine-id> --app carterdea-mcp-gateway

# Scale up memory if needed
fly scale memory 2048 --app carterdea-mcp-gateway
```

### Connection Issues

```bash
# Restart machine
fly machine restart <machine-id> --app carterdea-mcp-gateway

# Check logs for errors
fly logs --app carterdea-mcp-gateway
```

### Authentication Errors

Verify credentials are set:

```bash
fly secrets list --app carterdea-mcp-gateway
```

Test credentials directly:

**Trello:**
```bash
curl "https://api.trello.com/1/members/me/boards?key=YOUR_KEY&token=YOUR_TOKEN"
```

**Harvest:**
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Harvest-Account-Id: YOUR_ACCOUNT_ID" \
  "https://api.harvestapp.com/v2/users/me"
```

**Shopify:**
```bash
curl -H "X-Shopify-Access-Token: YOUR_TOKEN" \
  "https://YOUR_SHOP.myshopify.com/admin/api/2024-01/shop.json"
```

### mcp-aggregator Issues

If mcp-aggregator doesn't work with Bun runtime:

1. Update `Dockerfile` to use `node:18-alpine` base image
2. Change `bun add` to `npm install`
3. Change `bunx` to `npx` in `mcp-config.json`
4. Redeploy: `fly deploy`

## Local Testing

Test the gateway locally with Bun:

```bash
# Install dependencies
bun add -g @mcp/aggregator supergateway

# Set environment variables
export TRELLO_API_KEY="..."
export TRELLO_TOKEN="..."
export HARVEST_ACCOUNT_ID="..."
export HARVEST_ACCESS_TOKEN="..."
export SHOPIFY_SHOP_URL="..."
export SHOPIFY_ADMIN_API_TOKEN="..."
export MCP_CONFIG="./mcp-config.json"
export PORT=8080

# Start gateway
supergateway --port 8080 --stdio mcp-aggregator
```

Test SSE endpoint:

```bash
curl -N http://localhost:8080/sse
```

## License

MIT
