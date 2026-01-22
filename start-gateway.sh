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

# Get list of enabled servers
ENABLED_SERVERS=$(docker mcp server ls 2>/dev/null | tail -n +4 | awk '{print $1}' | tr '\n' ',' | sed 's/,$//')

echo "Starting Docker MCP Gateway on port 8080..."
echo "Enabled MCP Toolkit servers: $ENABLED_SERVERS"
echo "Custom Docker images: trello, harvest"
echo ""

# Run gateway with all enabled servers + custom Docker images
docker mcp gateway run \
    --transport sse \
    --port 8080 \
    --enable-all-servers \
    --oci-ref docker://mcp/trello:latest \
    --oci-ref docker://mcp/harvest:latest
