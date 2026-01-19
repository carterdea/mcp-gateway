# Poke MCP Separate Endpoints Design Doc

## Problem Context

Option A (single aggregated endpoint) may cause tool context overload in Poke.com when all 4 MCP servers expose their tools simultaneously. MCP best practice recommends "small, focused servers" rather than large aggregations.

Current state (if Option A implemented):

- Single SSE endpoint aggregates GitHub, Playwright, Trello, Harvest
- All tools from all servers always available to Poke
- No way to invoke specific server by name
- Potential for tool name conflicts

Pain points:

- Poke may struggle with too many tools in context
- Debugging harder when all servers mixed
- Cannot selectively use specific integrations

## Proposed Solution

Run separate gateway instances per MCP server, route via Nginx reverse proxy, expose all through single Ngrok tunnel with path-based routing.

- 4 gateway instances on ports 8081-8084
- Nginx routes `/github/sse`, `/playwright/sse`, etc. to correct gateway
- Single Ngrok tunnel to Nginx
- 4 separate Poke integrations, one per server

## Goals and Non-Goals

### Goals

- Separate endpoint per MCP server with isolated tool context
- Path-based routing through single Ngrok tunnel
- Ability to invoke specific MCP by integration name in Poke
- Clean separation for easier debugging
- Follow MCP best practice of small, focused servers

### Non-Goals

- Load balancing or failover between servers
- Dynamic server discovery
- Authentication per-server (same auth model as Option A)
- Kubernetes/container orchestration

## Design

```text
┌─────────────────┐
│  Poke.com       │
│  (4 integrations)│
└────────┬────────┘
         │
    ┌────┴────┬─────────┬─────────┐
    │         │         │         │
    ▼         ▼         ▼         ▼
┌────────┐┌────────┐┌────────┐┌────────┐
│ /github││/playwrt││/trello ││/harvest│
│  /sse  ││  /sse  ││  /sse  ││  /sse  │
└────┬───┘└────┬───┘└────┬───┘└────┬───┘
     │         │         │         │
     └─────────┴─────────┴─────────┘
               │ Ngrok
               ▼
     ┌────────────────────┐
     │  Nginx             │
     │  Reverse Proxy     │
     │  localhost:80      │
     └────────┬───────────┘
              │
     ┌────┬───┴───┬────┐
     ▼    ▼       ▼    ▼
   :8081 :8082  :8083 :8084
   GitHub Playw Trello Harvest
   Gateway instances
```

### Key Components

**4 Gateway Instances**: Each runs `docker mcp gateway run --transport sse --port 808X --servers <server>` exposing single MCP server.

**Nginx Reverse Proxy**: Routes paths to correct gateway port. Handles SSE-specific headers (no buffering, chunked encoding).

**Ngrok Tunnel**: Single tunnel to Nginx on port 80. Provides 4 logical endpoints via path routing.

**Poke Integrations**: 4 separate integrations, each pointing to specific path.

### Request Flow

1. Poke sends request to `https://xyz.ngrok.io/github/sse`
2. Ngrok forwards to `localhost:80/github/sse`
3. Nginx routes to `localhost:8081/sse`
4. GitHub gateway handles request, returns via SSE
5. Response flows back through Nginx → Ngrok → Poke

### Nginx Configuration

```nginx
location /github/sse {
    proxy_pass http://localhost:8081/sse;
    proxy_set_header Connection '';
    proxy_http_version 1.1;
    chunked_transfer_encoding off;
    proxy_buffering off;
    proxy_cache off;
}

location /playwright/sse {
    proxy_pass http://localhost:8082/sse;
    # same SSE headers...
}

location /trello/sse {
    proxy_pass http://localhost:8083/sse;
    # same SSE headers...
}

location /harvest/sse {
    proxy_pass http://localhost:8084/sse;
    # same SSE headers...
}
```

## Alternatives Considered

| Alternative | Pros | Cons | Why Not Chosen |
| ----------- | ---- | ---- | -------------- |
| Single gateway + Nginx filtering | Fewer processes | Complex filtering, unclear if gateway supports it | Filtering not well documented |
| Traefik MCP Gateway | Built for this use case | Different stack, learning curve | Stick with Docker gateway for consistency |
| 4 separate Ngrok tunnels | No Nginx needed | 4 URLs to manage, more Ngrok cost | Single tunnel simpler |
| Option A (aggregated) | Simpler setup | Context overload risk | That's what we're solving |

## Open Questions

- [ ] Resource impact of running 4 gateway processes?
- [ ] Does Nginx need additional SSE timeout configuration?
- [ ] Best way to health-check all 4 gateways?
- [ ] Should we use Docker Compose to manage all processes?

## Implementation Plan

### Phase 1: Multiple Gateway Setup

- [ ] Create script to run 4 gateway instances
  - [ ] Gateway 1: GitHub on port 8081
  - [ ] Gateway 2: Playwright on port 8082
  - [ ] Gateway 3: Trello on port 8083
  - [ ] Gateway 4: Harvest on port 8084
- [ ] Test each gateway individually
- [ ] Document resource usage (CPU/memory)

### Phase 2: Nginx Reverse Proxy

- [ ] Install Nginx locally (or use Docker Nginx)
- [ ] Create Nginx config with 4 locations
- [ ] Add SSE-specific headers to prevent buffering
- [ ] Test Nginx routing locally

### Phase 3: Ngrok Integration

- [ ] Update Ngrok to tunnel to Nginx (port 80)
- [ ] Test all 4 endpoints via Ngrok:
  - [ ] `https://xyz.ngrok.io/github/sse`
  - [ ] `https://xyz.ngrok.io/playwright/sse`
  - [ ] `https://xyz.ngrok.io/trello/sse`
  - [ ] `https://xyz.ngrok.io/harvest/sse`

### Phase 4: Poke Configuration

- [ ] Create 4 separate integrations in Poke:
  - [ ] "GitHub MCP" → `https://xyz.ngrok.io/github/sse`
  - [ ] "Playwright MCP" → `https://xyz.ngrok.io/playwright/sse`
  - [ ] "Trello MCP" → `https://xyz.ngrok.io/trello/sse`
  - [ ] "Harvest MCP" → `https://xyz.ngrok.io/harvest/sse`
- [ ] Test invoking specific integrations by name
- [ ] Verify reduced context/tool overload

### Phase 5: Automation & Testing

- [ ] Update startup scripts:
  - [ ] Start all 4 gateways
  - [ ] Start Nginx
  - [ ] Start Ngrok
- [ ] Create stop script to cleanly shutdown all processes
- [ ] Test end-to-end from fresh start
- [ ] Document new architecture in README

## Appendix

### Option A vs Option B Comparison

| Aspect | Option A (Single) | Option B (Separate) |
| ------ | ----------------- | ------------------- |
| Setup Complexity | Simple | Moderate |
| Poke Configuration | 1 integration | 4 integrations |
| Tool Context | All tools always | Only relevant tools |
| Resource Usage | 1 gateway | 4 gateways + Nginx |
| Debugging | Harder (mixed) | Easier (isolated) |
| MCP Best Practice | Against | Follows |

### Migration from Option A

1. Keep Option A running while setting up Option B
2. Test Option B with separate Ngrok tunnel
3. Create new Poke integrations (don't delete Option A yet)
4. Compare performance and usability
5. Once satisfied, remove Option A from Poke
6. Shut down Option A gateway
7. Update startup scripts for Option B only

### References

- [Traefik MCP Gateway](https://doc.traefik.io/traefik-hub/mcp-gateway/guides/getting-started)
- [HN: MCP Multiple Servers Context Issue](https://news.ycombinator.com/item?id=45954572)
- [Nginx SSE Proxy Config](https://stackoverflow.com/questions/27898622/server-sent-events-and-nginx)
- [Docker MCP Gateway per-server paths](https://gist.github.com/ecorkran/7849c927587e5d396a64bc6a4d2a683b)

### Related Documents

- [POKE_MCP_INTEGRATION_PLAN.md](./POKE_MCP_INTEGRATION_PLAN.md) - Option A: Single aggregated endpoint (simpler, try first)
