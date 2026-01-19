#!/bin/bash
# Set up Docker MCP secrets for Trello and Harvest

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load environment variables from .env
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "Error: .env file not found"
    echo "Create .env with:"
    echo "  TRELLO_API_KEY=your_key"
    echo "  TRELLO_TOKEN=your_token"
    echo "  HARVEST_ACCOUNT_ID=your_id"
    echo "  HARVEST_ACCESS_TOKEN=your_token"
    exit 1
fi

echo "Setting Docker MCP secrets..."

# Set Trello secrets
if [ -n "$TRELLO_API_KEY" ]; then
    echo "$TRELLO_API_KEY" | docker mcp secret set trello.api_key
    echo "Set: trello.api_key"
fi

if [ -n "$TRELLO_TOKEN" ]; then
    echo "$TRELLO_TOKEN" | docker mcp secret set trello.token
    echo "Set: trello.token"
fi

# Set Harvest secrets
if [ -n "$HARVEST_ACCOUNT_ID" ]; then
    echo "$HARVEST_ACCOUNT_ID" | docker mcp secret set harvest.account_id
    echo "Set: harvest.account_id"
fi

if [ -n "$HARVEST_ACCESS_TOKEN" ]; then
    echo "$HARVEST_ACCESS_TOKEN" | docker mcp secret set harvest.access_token
    echo "Set: harvest.access_token"
fi

echo ""
echo "Secrets configured! You can verify with:"
echo "  docker mcp secret list"
