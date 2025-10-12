#!/bin/bash

# MCP Test Bot Setup Script
# This script deploys the MCP test bot to the VPS and verifies the setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() { echo -e "${BLUE}ℹ ${1}${NC}"; }
echo_success() { echo -e "${GREEN}✅ ${1}${NC}"; }
echo_warning() { echo -e "${YELLOW}⚠️  ${1}${NC}"; }
echo_error() { echo -e "${RED}❌ ${1}${NC}"; }

# Load .env file if it exists
if [ -f .env ]; then
    echo_info "Loading environment variables from .env file..."
    source .env
fi

# Configuration
VPS_HOST="${VPS_HOST:-46.101.135.160}"
VPS_USER="${VPS_USER:-root}"
VPS_DEPLOY_DIR="/opt/hummingbot"

echo ""
echo_info "🤖 MCP Test Bot Setup Script"
echo_info "════════════════════════════════════"
echo ""

# Check if main deployment is running
echo_info "Checking if Hummingbot stack is running on VPS..."
if ! ssh "${VPS_USER}@${VPS_HOST}" "cd ${VPS_DEPLOY_DIR} && docker compose ps | grep -q 'hummingbot-api'" 2>/dev/null; then
    echo_error "Hummingbot API is not running on VPS!"
    echo_warning "Please run ./deploy.sh first to deploy the main stack"
    exit 1
fi
echo_success "Hummingbot stack is running"

# Copy bot files to VPS
echo_info "Copying MCP test bot files to VPS..."
ssh "${VPS_USER}@${VPS_HOST}" "mkdir -p ${VPS_DEPLOY_DIR}/data/bots/mcp_test_bot"

# Copy the bot directory
scp -r ../bots/mcp_test_bot/* "${VPS_USER}@${VPS_HOST}:${VPS_DEPLOY_DIR}/data/bots/mcp_test_bot/"

# Copy the script file
ssh "${VPS_USER}@${VPS_HOST}" "mkdir -p ${VPS_DEPLOY_DIR}/data/hummingbot/scripts"
scp ../scripts/mcp_test_bot.py "${VPS_USER}@${VPS_HOST}:${VPS_DEPLOY_DIR}/data/hummingbot/scripts/"

echo_success "Bot files copied successfully"

# Verify API is accessible
echo_info "Verifying Hummingbot API is accessible..."
API_URL="http://${VPS_HOST}/api"
if curl -s -o /dev/null -w "%{http_code}" "${API_URL}/docs" | grep -q "200\|307"; then
    echo_success "API is accessible at ${API_URL}"
else
    echo_warning "API might not be accessible from external network"
    echo_info "This is normal if you haven't configured external access yet"
fi

echo ""
echo_success "════════════════════════════════════"
echo_success "🎉 MCP Test Bot Setup Complete!"
echo_success "════════════════════════════════════"
echo ""
echo_info "📝 Next Steps:"
echo ""
echo "  1️⃣  ${YELLOW}Access the API documentation:${NC}"
echo "     http://${VPS_HOST}/api/docs"
echo ""
echo "  2️⃣  ${YELLOW}Test API connectivity:${NC}"
echo "     curl http://${VPS_HOST}/api/health"
echo ""
echo "  3️⃣  ${YELLOW}View bot files on VPS:${NC}"
echo "     ssh ${VPS_USER}@${VPS_HOST} 'ls -la ${VPS_DEPLOY_DIR}/data/bots/mcp_test_bot/'"
echo ""
echo "  4️⃣  ${YELLOW}Set up MCP connection (see MCP_SETUP.md)${NC}"
echo ""
echo_info "💡 Bot Configuration:"
echo "  - Bot Name: mcp_test_bot"
echo "  - Trading Mode: Paper Trading (no real funds)"
echo "  - Exchanges: Binance, KuCoin"
echo "  - Trading Pairs: BTC-USDT, ETH-USDT"
echo ""
