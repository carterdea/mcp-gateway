#!/bin/bash
# Start Ngrok tunnel to MCP Gateway

DOMAIN="carterdea-mcp.ngrok.pizza"

echo "Starting Ngrok tunnel to localhost:8080..."
echo "Domain: https://$DOMAIN"
echo ""

ngrok http 8080 --domain=$DOMAIN
