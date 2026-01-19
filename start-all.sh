#!/bin/bash
# Start both MCP Gateway and Ngrok tunnel

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== MCP Gateway + Ngrok Startup ==="
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

# Start ngrok (foreground)
ngrok http 8080

# Cleanup on exit
kill $GATEWAY_PID 2>/dev/null
