# Poke MCP Integration Design Doc

## Problem Context

MCP servers (GitHub, Playwright, Trello, Harvest) are configured in Docker Desktop but only accessible locally via stdio. Poke.com requires an SSE endpoint over HTTPS to connect to MCP servers.

Current state:

- GitHub and Playwright MCPs configured in Docker Desktop
- Trello and Harvest MCPs not yet configured
- No remote access to any MCP servers
- Cannot use MCP tools from Poke.com

Pain points:

- Local-only MCP access limits workflow flexibility
- Manual tool invocation required outside Poke
- No unified interface for all productivity tools

## Proposed Solution

Use Docker MCP Gateway to aggregate all 4 MCP servers into a single SSE endpoint, then expose via Ngrok tunnel for Poke.com access.

- Docker MCP Gateway aggregates stdio-based MCPs into one SSE server
- Ngrok provides HTTPS tunnel to localhost
- Poke.com connects to Ngrok URL as MCP endpoint
- Single connection gives access to all tools

## Goals and Non-Goals

### Goals

- Configure Trello and Harvest MCPs in Docker Desktop
- Run Docker MCP Gateway in SSE mode aggregating all 4 servers
- Expose gateway via Ngrok tunnel with stable URL
- Connect Poke.com to the Ngrok SSE endpoint
- Verify all MCP tools accessible from Poke.com

### Non-Goals

- Authentication/authorization layer (relying on Ngrok URL obscurity for now)
- High availability or redundancy
- Custom MCP server development
- Mobile access to MCP tools

## Design

```
┌─────────────────┐
│  Poke.com       │
│  (Remote)       │
└────────┬────────┘
         │ HTTPS
         ▼
┌──────────────────────────────┐
│  Ngrok Tunnel                │
│  https://xyz.ngrok.io/sse    │
└────────┬─────────────────────┘
         │ HTTP
         ▼
┌──────────────────────────────┐
│  Docker MCP Gateway          │
│  localhost:8080/sse          │
│                              │
│  docker mcp gateway run      │
│    --transport sse           │
│    --port 8080              │
│    --servers github,         │
│      playwright,trello,      │
│      harvest                 │
└────────┬─────────────────────┘
         │ stdio (internal)
         ▼
┌──────────────────────────────┐
│  Docker Desktop MCPs         │
│  - GitHub (existing)         │
│  - Playwright (existing)     │
│  - Trello (new)              │
│  - Harvest (new)             │
└──────────────────────────────┘
```

### Key Components

**Docker MCP Gateway**: Aggregates multiple stdio-based MCP servers into a single SSE endpoint. Runs as `docker mcp gateway run --transport sse --port 8080`.

**Ngrok Tunnel**: Provides HTTPS ingress to localhost:8080. Handles TLS termination and provides stable public URL.

**Docker Desktop MCPs**: Individual MCP servers configured in Docker Desktop settings. Each server runs via stdio and is managed by Docker.

### Request Flow

1. Poke.com initiates SSE connection to `https://xyz.ngrok.io/sse`
2. Ngrok forwards request to `localhost:8080/sse`
3. Docker MCP Gateway receives request, maintains SSE connection
4. Tool calls routed to appropriate MCP server via stdio
5. Responses aggregated and returned over SSE

## Alternatives Considered

| Alternative | Pros | Cons | Why Not Chosen |
|-------------|------|------|----------------|
| Option B: Separate endpoints per server | Cleaner context, isolated failures | Multiple Ngrok tunnels, multiple Poke integrations | More complexity; try aggregated first |
| Supergateway + mcp-aggregator | More control over SSE behavior | Additional dependencies, more moving parts | Docker MCP Gateway is simpler |
| Cloudflare Tunnel | Free, more stable than Ngrok | More setup, requires domain | Ngrok faster to prototype |
| Direct port forwarding | No third-party dependency | Requires static IP, firewall config | Not practical for development |

## Open Questions

- [ ] Does Docker MCP Gateway send SSE heartbeats to prevent Ngrok timeout?
- [ ] Will 4 MCP servers overwhelm Poke's tool context window?
- [ ] Should we use Ngrok reserved domain for stable URL?
- [ ] Do we need API key auth on the gateway?

## Implementation Plan

### Phase 1: Docker Desktop MCP Configuration

- [x] Locate Docker Desktop MCP configuration
  - [x] Check `~/.docker/config.json`
  - [x] Check Docker Desktop UI settings
  - [x] Document current GitHub and Playwright MCP configurations
- [x] Add Trello MCP server configuration
  - [x] Package: `@delorenj/mcp-server-trello`
  - [x] Environment variables from `.env`: `TRELLO_API_KEY`, `TRELLO_TOKEN`
  - [x] Created custom Docker image: `docker/trello-mcp/Dockerfile` (Bun-based)
  - [ ] Test Trello MCP locally in Docker Desktop
- [x] Add Harvest MCP server configuration
  - [x] Package: `@standardbeagle/harvest-mcp`
  - [x] Environment variables from `.env`: `HARVEST_ACCOUNT_ID`, `HARVEST_ACCESS_TOKEN`
  - [x] Created custom Docker image: `docker/harvest-mcp/Dockerfile` (Bun-based)
  - [ ] Test Harvest MCP locally in Docker Desktop
- [ ] Verify all 4 MCPs appear in Docker Desktop

### Phase 2: Docker MCP Gateway Setup

- [x] Verify Docker MCP Gateway is installed
  - [x] Run `docker mcp gateway --help` to confirm availability
  - [x] Update Docker Desktop if gateway is not available
- [ ] Test gateway in stdio mode first (sanity check)
  - [ ] Run `docker mcp gateway run --transport stdio`
  - [ ] Verify it can connect to configured MCPs
- [x] Configure gateway for SSE mode
  - [x] Run `docker mcp gateway run --transport sse --port 8080`
  - [ ] Verify gateway starts successfully on port 8080
  - [ ] Test local access to `http://localhost:8080/sse`
- [x] Filter to only expose desired servers
  - [x] Run with `--servers github-official,playwright,docker://mcp/trello:latest,docker://mcp/harvest:latest`
  - [x] Document exact command used in `start-gateway.sh`
  - [ ] Verify only desired servers are exposed

### Phase 3: Ngrok Tunnel Setup

- [ ] Install/update Ngrok CLI
  - [ ] Run `ngrok version` to check current version
  - [ ] Update if needed via `brew upgrade ngrok` (macOS)
- [ ] Configure Ngrok authentication
  - [ ] Verify Ngrok account is authenticated
  - [ ] Document account details (paid plan)
- [x] Create Ngrok tunnel to gateway
  - [x] Created `start-ngrok.sh` script to run `ngrok http 8080`
  - [ ] Document the generated Ngrok URL
  - [ ] Test external access to `https://xyz.ngrok.io/sse`
- [ ] Configure persistent Ngrok settings
  - [ ] Create/update `~/.ngrok2/ngrok.yml` config file
  - [ ] Consider reserved domain (paid feature)
  - [ ] Document tunnel configuration

### Phase 4: Poke.com Integration

- [ ] Add MCP integration in Poke
  - [ ] Navigate to <https://poke.com/settings/connections/integrations/new>
  - [ ] Create custom MCP integration
  - [ ] Name: "Docker MCPs" or similar
  - [ ] MCP Server URL: `https://xyz.ngrok.io/sse`
  - [ ] Add API key if needed (check if gateway requires auth)
- [ ] Test connection from Poke
  - [ ] Verify Poke shows "Connected" status
  - [ ] Check for any connection errors
- [ ] Test each MCP server's tools
  - [ ] Test GitHub MCP tools in Poke chat
  - [ ] Test Playwright MCP tools in Poke chat
  - [ ] Test Trello MCP tools in Poke chat
  - [ ] Test Harvest MCP tools in Poke chat
  - [ ] Document any issues or limitations

### Phase 5: Automation & Persistence

- [x] Create startup script for gateway
  - [x] Script location: `/Users/carterdeangelis/Sites/mcp-gateway/start-gateway.sh`
  - [x] Script should start Docker MCP Gateway with correct flags
  - [x] Make script executable: `chmod +x start-gateway.sh`
- [x] Create startup script for Ngrok
  - [x] Script location: `/Users/carterdeangelis/Sites/mcp-gateway/start-ngrok.sh`
  - [x] Script should start Ngrok tunnel to port 8080
  - [x] Make script executable: `chmod +x start-ngrok.sh`
- [x] Create combined startup script
  - [x] Script location: `/Users/carterdeangelis/Sites/mcp-gateway/start-all.sh`
  - [x] Starts both gateway and ngrok
  - [x] Displays both URLs when ready
  - [x] Document usage in README
- [x] Create build script for custom Docker images
  - [x] Script location: `/Users/carterdeangelis/Sites/mcp-gateway/build-mcps.sh`
  - [x] Builds Trello and Harvest MCP Docker images
- [x] Create secrets setup script
  - [x] Script location: `/Users/carterdeangelis/Sites/mcp-gateway/setup-secrets.sh`
  - [x] Configures Docker MCP secrets from `.env`
- [ ] Optional: Configure as macOS login item
  - [ ] Create LaunchAgent plist (if desired)
  - [ ] Test automatic startup on system boot
  - [ ] Document how to enable/disable

### Phase 6: Documentation & Testing

- [x] Update README.md
  - [x] Add architecture diagram
  - [x] Document all commands
  - [x] Add troubleshooting section
- [ ] Create troubleshooting guide
  - [ ] Docker Desktop MCP issues
  - [ ] Gateway connection issues
  - [ ] Ngrok tunnel issues
  - [ ] Poke.com connection issues
- [ ] Test end-to-end workflow
  - [ ] Fresh start from shutdown state
  - [ ] Verify startup scripts work
  - [ ] Verify Poke can connect
  - [ ] Verify all tools work
- [ ] Document known limitations
  - [ ] Ngrok timeout concerns (7-minute HTTP timeout)
  - [ ] Heartbeat/keep-alive needs (if required)
  - [ ] Any tool conflicts or overlaps

## Appendix

### Known Risks

| Risk | Impact | Mitigation | Fallback |
| ---- | ------ | ---------- | -------- |
| Ngrok SSE timeout (~7 min) | Connection drops | Test if gateway sends heartbeats | Add proxy layer for heartbeats |
| Tool context overload | Poke confused by too many tools | Monitor tool usage | Switch to Option B (separate endpoints) |
| Gateway heartbeat unknown | May not prevent timeouts | Test long-running connections | Custom proxy/wrapper |

### Environment Variables

Required in `.env`:

```
TRELLO_API_KEY=<key>
TRELLO_TOKEN=<token>
HARVEST_ACCOUNT_ID=<id>
HARVEST_ACCESS_TOKEN=<token>
```

### References

- [Docker MCP Gateway GitHub](https://github.com/docker/mcp-gateway)
- [Docker MCP Gateway Docs](https://docs.docker.com/ai/mcp-catalog-and-toolkit/mcp-gateway/)
- [Poke Managing Integrations](https://poke.com/docs/managing-integrations)
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)
- [Ngrok SSE Support](https://github.com/inconshreveable/ngrok/issues/135)

### Related Documents

- [POKE_MCP_SEPARATE_ENDPOINTS_PLAN.md](./POKE_MCP_SEPARATE_ENDPOINTS_PLAN.md) - Option B: Separate endpoints per server (fallback if context overload occurs)
