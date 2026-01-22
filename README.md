# MCP Gateway

Model Context Protocol (MCP) gateway to expose multiple MCP servers via SSE for Poke.com.

## Deployment Options

### Option A: Docker Desktop + Ngrok (Local Server)

Run on your Mac mini with Docker MCP Gateway and expose via Ngrok.

```
Poke.com → Ngrok → localhost:8080 → Docker MCP Gateway → MCP Servers
                                                          ├── GitHub (catalog)
                                                          ├── Playwright (catalog)
                                                          ├── Trello (custom Docker)
                                                          └── Harvest (custom Docker)
```

**Quick Start:**
```bash
cd ~/Sites/mcp-gateway
./build-mcps.sh        # Build custom Docker images (first time)
./setup-secrets.sh     # Configure API keys
./start-all.sh         # Start gateway + ngrok
```

**Ngrok URL:**
```
https://carterdea-mcp.ngrok.pizza/sse
```

See [Local Setup](#local-setup-docker-desktop) below.

### Option B: Fly.io (Cloud)

Deployed on Fly.io using mcp-aggregator and Supergateway.

```
Poke.com (MCP Client)
    ↓ SSE
Supergateway (stdio → SSE adapter)
    ↓ stdio
mcp-aggregator (combines MCPs)
    ↓ ↓ ↓
    Trello | Harvest | Shopify
        ↓      ↓        ↓
    REST APIs (external services)
```

**SSE Endpoint:**
```
https://carterdea-mcp-gateway.fly.dev/sse
```

---

## Local Setup (Docker Desktop)

### Prerequisites
- Docker Desktop with MCP Toolkit
- Ngrok CLI (authenticated)

### 1. Build custom MCP images

```bash
./build-mcps.sh
```

This builds Docker images for MCPs not in Docker's catalog:
- `mcp/trello:latest` - Trello board/card management
- `mcp/harvest:latest` - Harvest time tracking

### 2. Configure secrets

Create `.env` with your API credentials:
```bash
TRELLO_API_KEY=your_api_key
TRELLO_TOKEN=your_token
HARVEST_ACCOUNT_ID=your_account_id
HARVEST_ACCESS_TOKEN=your_access_token

# Gateway auth token (generate with: openssl rand -hex 32)
MCP_GATEWAY_AUTH_TOKEN=your_secure_token
```

Then run:
```bash
./setup-secrets.sh
```

Or manually:
```bash
docker mcp secret set trello.api_key
docker mcp secret set trello.token
docker mcp secret set harvest.account_id
docker mcp secret set harvest.access_token
```

### 3. Start gateway

```bash
./start-gateway.sh
```

This runs Docker MCP Gateway aggregating:
- `github-official` (from Docker catalog)
- `playwright` (from Docker catalog)
- `docker://mcp/trello:latest` (custom image)
- `docker://mcp/harvest:latest` (custom image)

### 4. Start Ngrok (separate terminal)

```bash
./start-ngrok.sh
```

This opens a tunnel at `https://carterdea-mcp.ngrok.pizza`

### 5. Connect Poke.com

1. Go to https://poke.com/settings/connections/integrations/new
2. Create MCP integration with:
   - **URL**: `https://carterdea-mcp.ngrok.pizza/sse`
   - **Auth Header**: `Authorization: Bearer YOUR_MCP_GATEWAY_AUTH_TOKEN`

### 6. Auto-start on Boot (Optional)

To have the gateway start automatically when the Mac mini boots:

```bash
# Copy LaunchAgent to system location
cp com.carterdea.mcp-gateway.plist ~/Library/LaunchAgents/

# Load the agent (starts immediately)
launchctl load ~/Library/LaunchAgents/com.carterdea.mcp-gateway.plist
```

To stop and disable:

```bash
launchctl unload ~/Library/LaunchAgents/com.carterdea.mcp-gateway.plist
```

View logs:

```bash
tail -f /tmp/mcp-gateway.log
tail -f /tmp/mcp-gateway-error.log
```

---

## Fly.io Deployment

### Current Configuration
- **MCP Servers**: Trello, Harvest, Shopify
- **Aggregator**: mcp-aggregator
- **Gateway**: Supergateway
- **Runtime**: Bun
- **Platform**: Fly.io (iad region)
- **Resources**: 1GB RAM, 1 shared vCPU

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
