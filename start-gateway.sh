#!/bin/bash
# Start Docker MCP Gateway with all configured servers

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

# Check if custom images exist (only builds if missing)
if ! docker images --format '{{.Repository}}' | grep -q "^mcp/trello$"; then
    echo "Custom MCP images not found. Run ./build-mcps.sh first."
    exit 1
fi

echo "Starting Docker MCP Gateway on port 8080..."
echo "Servers: github-official, playwright, trello, harvest"
echo ""

# Run gateway with both catalog and custom servers
# Note: Custom images need environment variables passed
docker mcp gateway run \
    --transport sse \
    --port 8080 \
    --servers github-official,playwright,docker://mcp/trello:latest,docker://mcp/harvest:latest

# If the above doesn't work with custom images, try this alternative:
# docker mcp gateway run --transport sse --port 8080 --servers github-official,playwright
