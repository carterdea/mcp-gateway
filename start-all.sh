#!/bin/bash
# Start both MCP Gateway and Ngrok tunnel

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== MCP Gateway + Ngrok Startup ==="
echo ""

# Initial delay to let system services start
echo "Waiting 10s for system startup..."
sleep 10

# Wait for Docker to be available (exponential backoff, max ~5 minutes)
echo "Waiting for Docker..."
WAITED=0
DELAY=1
while ! docker info > /dev/null 2>&1; do
    if [ $WAITED -ge 300 ]; then
        echo "Error: Docker not available after ${WAITED}s"
        exit 1
    fi
    sleep $DELAY
    WAITED=$((WAITED + DELAY))
    echo "  Waiting for Docker... (${WAITED}s)"
    # Exponential backoff: 1, 2, 4, 8, 16, 32, cap at 32s
    DELAY=$((DELAY * 2))
    if [ $DELAY -gt 32 ]; then
        DELAY=32
    fi
done
echo "Docker is ready"
echo ""

# Start gateway in background
echo "Starting MCP Gateway..."
"$SCRIPT_DIR/start-gateway.sh" &
GATEWAY_PID=$!

# Wait for gateway to start
sleep 3

# Check if gateway is running
if ! curl -s http://localhost:8080/sse > /dev/null 2>&1; then
    echo "Warning: Gateway may not be responding on port 8080 yet"
fi

echo ""
echo "Starting Ngrok tunnel..."
echo "Press Ctrl+C to stop both services"
echo ""

# Start ngrok with reserved domain (foreground)
"$SCRIPT_DIR/start-ngrok.sh"

# Cleanup on exit
kill $GATEWAY_PID 2>/dev/null
