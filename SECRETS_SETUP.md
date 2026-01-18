# Fly.io Secrets Setup

This document contains the commands to set up all required secrets for the MCP Gateway on Fly.io.

## Prerequisites

You need to obtain the following credentials:

### Trello
- **API Key**: https://trello.com/app-key
- **Token**: Use the authorization URL from the API key page (already configured)

### Harvest
- **Account ID**: Your Harvest account ID
- **Personal Access Token**: Create at https://id.getharvest.com/developers

### Shopify
- **Shop URL**: Your Shopify store URL (e.g., `mystore.myshopify.com`)
- **Admin API Token**: Create a custom app in your Shopify admin to get an Admin API token (starts with `shpat_`)

## Set All Secrets at Once

Run this command with your actual credentials:

```bash
fly secrets set \
  TRELLO_API_KEY="your_trello_api_key" \
  TRELLO_TOKEN="your_trello_token" \
  HARVEST_ACCOUNT_ID="your_harvest_account_id" \
  HARVEST_ACCESS_TOKEN="your_harvest_access_token" \
  SHOPIFY_SHOP_URL="mystore.myshopify.com" \
  SHOPIFY_ADMIN_API_TOKEN="shpat_..." \
  --app carterdea-mcp-gateway
```

## Set Secrets Individually

If you prefer to set them one at a time or only need to update specific credentials:

### Trello (Already Set)
```bash
fly secrets set \
  TRELLO_API_KEY="your_trello_api_key" \
  TRELLO_TOKEN="your_trello_token" \
  --app carterdea-mcp-gateway
```

### Harvest (New)
```bash
fly secrets set \
  HARVEST_ACCOUNT_ID="your_harvest_account_id" \
  HARVEST_ACCESS_TOKEN="your_harvest_access_token" \
  --app carterdea-mcp-gateway
```

### Shopify (New)
```bash
fly secrets set \
  SHOPIFY_SHOP_URL="mystore.myshopify.com" \
  SHOPIFY_ADMIN_API_TOKEN="shpat_..." \
  --app carterdea-mcp-gateway
```

## Verify Secrets

List all configured secrets (values are hidden):

```bash
fly secrets list --app carterdea-mcp-gateway
```

## Test Credentials

After setting secrets, verify they work by testing the APIs directly:

### Test Trello
```bash
curl "https://api.trello.com/1/members/me/boards?key=YOUR_KEY&token=YOUR_TOKEN"
```

### Test Harvest
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Harvest-Account-Id: YOUR_ACCOUNT_ID" \
  "https://api.harvestapp.com/v2/users/me"
```

### Test Shopify
```bash
curl -H "X-Shopify-Access-Token: YOUR_TOKEN" \
  "https://YOUR_SHOP.myshopify.com/admin/api/2024-01/shop.json"
```

## Important Notes

1. **Trello credentials** are already configured and working
2. **New credentials needed**: Harvest and Shopify
3. Setting secrets triggers a new deployment automatically
4. Secrets are encrypted and never shown in logs
5. If you make a mistake, just run the `fly secrets set` command again with the correct value

## Next Steps

After setting all secrets:

1. Deploy the updated gateway: `fly deploy`
2. Monitor logs: `fly logs --app carterdea-mcp-gateway`
3. Test the SSE endpoint: `curl -N https://carterdea-mcp-gateway.fly.dev/sse`
4. Add the SSE URL to Poke.com's MCP integration settings
