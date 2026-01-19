#!/bin/bash
# Build custom MCP Docker images for Docker Desktop

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Building Trello MCP Docker image..."
docker build -t mcp/trello:latest "$SCRIPT_DIR/docker/trello-mcp"

echo "Building Harvest MCP Docker image..."
docker build -t mcp/harvest:latest "$SCRIPT_DIR/docker/harvest-mcp"

echo ""
echo "Done! Images built:"
docker images | grep "mcp/"

echo ""
echo "Next steps:"
echo "1. Test custom MCPs with gateway:"
echo "   docker mcp gateway run --transport sse --port 8080 --servers docker://mcp/trello:latest,docker://mcp/harvest:latest"
echo ""
echo "2. Or include catalog servers too:"
echo "   docker mcp gateway run --transport sse --port 8080 --servers github-official,playwright,docker://mcp/trello:latest,docker://mcp/harvest:latest"
