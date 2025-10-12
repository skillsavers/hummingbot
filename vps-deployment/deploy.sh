#!/bin/bash

# Hummingbot VPS Production Deployment Script
# This script deploys Hummingbot with Nginx reverse proxy using Docker Compose

set -e

# Load .env file if it exists
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    source .env
fi

# Configuration
VPS_HOST="${VPS_HOST:-46.101.135.160}"
VPS_USER="${VPS_USER:-root}"
VPS_DEPLOY_DIR="/opt/hummingbot"
DOCKER_IMAGE="ghcr.io/skillsavers/hummingbot"
GITHUB_USERNAME="${GITHUB_USERNAME:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

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

echo ""
echo_info "🚀 Hummingbot Production Deployment Script"
echo_info "═══════════════════════════════════════════"
echo ""

# Check if we can connect to the VPS
echo_info "Testing connection to VPS: ${VPS_HOST}..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${VPS_USER}@${VPS_HOST}" exit 2>/dev/null; then
    echo_error "Cannot connect to VPS. Please ensure:"
    echo "   - SSH key is set up (run: ssh-copy-id ${VPS_USER}@${VPS_HOST})"
    echo "   - VPS is accessible"
    echo "   - Firewall allows SSH connections"
    exit 1
fi
echo_success "Connected to VPS successfully"

# Create deployment package
echo_info "Creating deployment package..."
TEMP_DIR=$(mktemp -d)
cp -r docker-compose.yml nginx "$TEMP_DIR/"
echo_success "Deployment package created"

# Transfer files to VPS
echo_info "Transferring files to VPS..."
ssh "${VPS_USER}@${VPS_HOST}" "mkdir -p ${VPS_DEPLOY_DIR}"
scp -r "$TEMP_DIR"/* "${VPS_USER}@${VPS_HOST}:${VPS_DEPLOY_DIR}/"
rm -rf "$TEMP_DIR"
echo_success "Files transferred successfully"

# Execute setup on VPS
echo_info "Setting up production environment on VPS..."
ssh "${VPS_USER}@${VPS_HOST}" bash -s "${GITHUB_USERNAME}" "${GITHUB_TOKEN}" << 'REMOTE_SCRIPT'
set -e

GITHUB_USERNAME="$1"
GITHUB_TOKEN="$2"

VPS_DEPLOY_DIR="/opt/hummingbot"
cd "${VPS_DEPLOY_DIR}"

echo "🔧 Installing Docker and Docker Compose..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

# Detect Docker Compose command (V1 vs V2)
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
    echo "✅ Docker Compose V2 detected"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
    echo "✅ Docker Compose V1 detected"
else
    echo "⚠️  Docker Compose not found, will be available after Docker installation"
    COMPOSE_CMD="docker compose"
fi

# Create data directories
echo "📁 Creating data directories..."
mkdir -p data/hummingbot/{conf,data,logs,certs,scripts,controllers}
mkdir -p data/hummingbot/conf/{connectors,strategies,controllers,scripts}
mkdir -p data/nginx/{cache,logs}
mkdir -p data/bots/credentials/master_account
mkdir -p nginx/ssl

# Set proper permissions
chmod -R 755 data/
chmod -R 755 nginx/

# Authenticate with GitHub Container Registry if credentials provided
if [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_TOKEN" ]; then
    echo "🔐 Authenticating with GitHub Container Registry..."
    echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin
    if [ $? -eq 0 ]; then
        echo "✅ Successfully authenticated with ghcr.io"
    else
        echo "❌ Failed to authenticate with ghcr.io"
        echo "⚠️  Will attempt to pull images without authentication (works for public images)"
    fi
else
    echo "⚠️  No GitHub credentials provided, attempting to pull public images..."
fi

# Pull latest images
echo "🐳 Pulling latest Docker images..."
$COMPOSE_CMD pull

# Stop existing containers
if $COMPOSE_CMD ps -q 2>/dev/null | grep -q .; then
    echo "🛑 Stopping existing containers..."
    $COMPOSE_CMD down
fi

# Start services
echo "🚀 Starting services with Docker Compose..."
$COMPOSE_CMD up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to start..."
sleep 5

# Check container status
echo ""
echo "📊 Container Status:"
$COMPOSE_CMD ps

# Create systemd service for auto-start on boot
echo ""
echo "⚙️  Creating systemd service..."

# Determine which compose command to use in systemd
SYSTEMD_COMPOSE_CMD="docker compose"
if command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
    SYSTEMD_COMPOSE_CMD="docker-compose"
fi

cat > /etc/systemd/system/hummingbot.service << SYSTEMD_EOF
[Unit]
Description=Hummingbot Trading Bot Stack
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/hummingbot
ExecStartPre=/usr/bin/${SYSTEMD_COMPOSE_CMD} pull -q
ExecStart=/usr/bin/${SYSTEMD_COMPOSE_CMD} up -d
ExecStop=/usr/bin/${SYSTEMD_COMPOSE_CMD} down
ExecReload=/usr/bin/${SYSTEMD_COMPOSE_CMD} pull -q
ExecReload=/usr/bin/${SYSTEMD_COMPOSE_CMD} up -d
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

systemctl daemon-reload
systemctl enable hummingbot.service
echo "✅ Systemd service created and enabled"

# Clean up
echo ""
echo "🧹 Cleaning up unused Docker resources..."
docker system prune -f --volumes 2>/dev/null || true

echo ""
echo "✅ Deployment complete!"
echo ""
REMOTE_SCRIPT

echo ""
echo_success "═══════════════════════════════════════════"
echo_success "🎉 Deployment Completed Successfully!"
echo_success "═══════════════════════════════════════════"
echo ""
echo_info "📝 Quick Reference Commands:"
echo ""
echo "  ${YELLOW}View logs:${NC}"
echo "    ssh ${VPS_USER}@${VPS_HOST} 'cd ${VPS_DEPLOY_DIR} && docker compose logs -f hummingbot'"
echo ""
echo "  ${YELLOW}Attach to Hummingbot:${NC}"
echo "    ssh ${VPS_USER}@${VPS_HOST} 'docker attach hummingbot'"
echo "    (Press Ctrl+P, Ctrl+Q to detach without stopping)"
echo ""
echo "  ${YELLOW}Check status:${NC}"
echo "    ssh ${VPS_USER}@${VPS_HOST} 'cd ${VPS_DEPLOY_DIR} && docker compose ps'"
echo "    ssh ${VPS_USER}@${VPS_HOST} 'systemctl status hummingbot'"
echo ""
echo "  ${YELLOW}Restart services:${NC}"
echo "    ssh ${VPS_USER}@${VPS_HOST} 'systemctl restart hummingbot'"
echo ""
echo "  ${YELLOW}Update to latest version:${NC}"
echo "    ssh ${VPS_USER}@${VPS_HOST} 'cd ${VPS_DEPLOY_DIR} && docker compose pull && docker compose up -d'"
echo ""
echo "  ${YELLOW}Stop services:${NC}"
echo "    ssh ${VPS_USER}@${VPS_HOST} 'systemctl stop hummingbot'"
echo ""
echo "  ${YELLOW}View Nginx logs:${NC}"
echo "    ssh ${VPS_USER}@${VPS_HOST} 'cd ${VPS_DEPLOY_DIR} && docker compose logs -f nginx'"
echo ""
echo_info "🌐 Nginx is running on ports 80 and 443"
echo_info "📁 Data is persisted in: ${VPS_DEPLOY_DIR}/data/"
echo ""
echo_warning "💡 Pro Tips:"
echo "  - Watchtower will automatically update containers hourly"
echo "  - Configure SSL certificates in nginx/ssl/ for HTTPS"
echo "  - Customize nginx/conf.d/default.conf for your domain"
echo ""
