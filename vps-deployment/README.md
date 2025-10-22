# Hummingbot API-Based Deployment

Complete Hummingbot trading infrastructure with API-driven bot orchestration, web dashboard, and containerized services.

## Architecture

This deployment provides a production-ready Hummingbot environment where **all bot management is done via API** - no manual configuration file editing required.

### Core Services

- **Hummingbot API** (port 8000) - REST API for bot orchestration
- **PostgreSQL** - Database for API persistence
- **EMQX MQTT Broker** - Real-time bot communication
- **Dashboard** (port 8501) - Web UI for monitoring and management
- **Nginx** - Reverse proxy (ready for SSL)
- **Watchtower** - Automatic container updates

### Bot Deployment Model

Bots are deployed **dynamically via API** as independent Docker containers. Each bot runs in its own container with:
- Isolated configuration
- Separate logs and data
- Real-time MQTT connection to API
- Encrypted credential storage

## Quick Start

### Prerequisites

1. Docker and Docker Compose installed
2. `.env` file configured with all credentials
3. Controllers copied to `data/bots/controllers/`

### 1. Configure Environment

All container configuration is managed via `.env` file:

```bash
# Copy example and configure
cp .env.example .env
nano .env
```

**Required variables** (see [DOCKER_ENV_CONFIG.md](DOCKER_ENV_CONFIG.md) for details):
- `CONFIG_PASSWORD` - Hummingbot master encryption password
- `API_USERNAME` / `API_PASSWORD` - API authentication
- `POSTGRES_PASSWORD` - Database password
- `BROKER_USERNAME` / `BROKER_PASSWORD` - MQTT credentials
- `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD` - Web UI login

### 2. Start Infrastructure

```bash
docker-compose up -d
```

This starts all 6 core services. Wait 30 seconds for initialization.

### 3. Verify Services

```bash
# Check all containers running
docker-compose ps

# Test API authentication
source .env
curl -u "$API_USERNAME:$API_PASSWORD" http://localhost:8000/accounts/

# Access dashboard
open http://localhost:8501
```

### 4. Add Exchange Credentials

```bash
source .env

curl -X POST "http://localhost:8000/accounts/add-credential/master_account/binance_perpetual_testnet" \
  -H "Content-Type: application/json" \
  -u "$API_USERNAME:$API_PASSWORD" \
  -d '{
    "binance_perpetual_testnet_api_key": "YOUR_API_KEY",
    "binance_perpetual_testnet_api_secret": "YOUR_API_SECRET"
  }'
```

### 5. Deploy a Bot

See [BOT_DEPLOYMENT_SUCCESS.md](BOT_DEPLOYMENT_SUCCESS.md) for complete bot deployment guide with controller configuration examples.

## File Structure

```
vps-deployment/
├── .env                          # All configuration (DO NOT COMMIT)
├── .env.example                  # Template without secrets
├── docker-compose.yml            # Infrastructure definition
├── nginx/
│   ├── nginx.conf               # Main Nginx config
│   ├── conf.d/                  # Server blocks
│   └── ssl/                     # SSL certificates (optional)
├── data/
│   ├── bots/
│   │   ├── controllers/         # Controller implementations
│   │   ├── credentials/         # Encrypted exchange credentials
│   │   ├── conf/               # Controller configurations
│   │   └── instances/          # Bot instance containers
│   ├── dashboard/              # Dashboard data
│   └── nginx/                  # Nginx logs and cache
└── scripts/                     # Optional automation scripts

Documentation:
├── README.md                    # This file
├── BOT_DEPLOYMENT_SUCCESS.md    # Complete bot deployment guide
├── DOCKER_ENV_CONFIG.md         # .env variable reference
├── ENV_DEPLOYMENT_CHECKLIST.md  # VPS deployment checklist
└── CLAUDE.md                    # API limitations and notes
```

## Bot Management via API

### List Available Controllers

```bash
curl -u "$API_USERNAME:$API_PASSWORD" http://localhost:8000/controllers/
```

### Create Controller Configuration

```bash
curl -X POST "http://localhost:8000/controllers/configs/my_strategy" \
  -H "Content-Type: application/json" \
  -u "$API_USERNAME:$API_PASSWORD" \
  -d '{
    "id": "my_strategy",
    "controller_name": "pmm_simple",
    "controller_type": "market_making",
    "connector_name": "binance_perpetual_testnet",
    "trading_pair": "BTC-USDT",
    "total_amount_quote": 50,
    "buy_spreads": [0.01, 0.02],
    "sell_spreads": [0.01, 0.02],
    "leverage": 1
  }'
```

### Deploy Bot Instance

```bash
curl -X POST "http://localhost:8000/bot-orchestration/deploy-v2-controllers" \
  -H "Content-Type: application/json" \
  -u "$API_USERNAME:$API_PASSWORD" \
  -d '{
    "instance_name": "my_bot",
    "credentials_profile": "master_account",
    "controllers_config": ["my_strategy"],
    "headless": true
  }'
```

### Monitor Bot

```bash
# Check bot status
curl -u "$API_USERNAME:$API_PASSWORD" http://localhost:8000/bot-orchestration/status

# View bot logs
docker logs my_bot -f

# Check active orders
curl -X POST "http://localhost:8000/trading/orders/active" \
  -H "Content-Type: application/json" \
  -u "$API_USERNAME:$API_PASSWORD" \
  -d '{"account_name": "master_account", "connector_name": "binance_perpetual_testnet"}'
```

## VPS Deployment

### Step 1: Copy Files to VPS

```bash
# Copy .env (contains all secrets)
scp .env root@YOUR_VPS_IP:/root/hummingbot-deployment/

# Copy docker configuration
scp docker-compose.yml root@YOUR_VPS_IP:/root/hummingbot-deployment/
scp -r nginx/ root@YOUR_VPS_IP:/root/hummingbot-deployment/
scp -r data/bots/controllers/ root@YOUR_VPS_IP:/root/hummingbot-deployment/data/bots/
```

### Step 2: Start on VPS

```bash
ssh root@YOUR_VPS_IP

cd /root/hummingbot-deployment

# Verify .env exists
ls -la .env

# Start all containers
docker-compose up -d

# Wait for initialization
sleep 30

# Verify all running
docker-compose ps
```

### Step 3: Add Credentials and Deploy

Follow the same API workflow as local deployment to:
1. Add exchange credentials
2. Create controller configurations
3. Deploy bot instances

See [ENV_DEPLOYMENT_CHECKLIST.md](ENV_DEPLOYMENT_CHECKLIST.md) for complete VPS deployment guide.

## Monitoring

### Container Health

```bash
# All containers
docker-compose ps

# Specific service logs
docker-compose logs -f hummingbot-api

# Bot instance logs
docker logs <instance_name> -f
```

### API Health Checks

```bash
# Bot orchestration status
curl -u "$API_USERNAME:$API_PASSWORD" http://localhost:8000/bot-orchestration/status

# Database connectivity
docker exec hummingbot-postgres pg_isready -U hbot -d hummingbot_api

# MQTT broker status
docker exec hummingbot-broker /opt/emqx/bin/emqx_ctl status
```

### Resource Usage

```bash
docker stats
```

## Maintenance

### Update Containers

Watchtower automatically checks for updates every hour. For manual updates:

```bash
docker-compose pull
docker-compose up -d
```

### Backup

```bash
# Backup everything
tar czf hummingbot-backup-$(date +%Y%m%d).tar.gz \
  .env \
  docker-compose.yml \
  data/ \
  nginx/

# Backup database only
docker exec hummingbot-postgres pg_dump -U hbot hummingbot_api > backup.sql
```

### Restore

```bash
# Extract backup
tar xzf hummingbot-backup-YYYYMMDD.tar.gz

# Restart services
docker-compose up -d
```

## Security

### Environment File Protection

```bash
# Set proper permissions
chmod 600 .env

# Verify it's ignored by git
grep ".env" .gitignore
```

### Encrypted Backup

```bash
# Encrypt .env for safe storage
gpg -c .env
# Creates .env.gpg - store this securely

# To restore
gpg -d .env.gpg > .env
```

### Firewall (VPS)

```bash
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw enable
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs <service_name>

# Verify .env variables
grep -E "^[A-Z_]+=" .env | wc -l
# Should show at least 13 variables

# Restart services
docker-compose restart
```

### API Authentication Fails

```bash
# Verify credentials
source .env
echo "Username: $API_USERNAME"
echo "Password: $API_PASSWORD"

# Test with verbose output
curl -v -u "$API_USERNAME:$API_PASSWORD" http://localhost:8000/accounts/
```

### Bot Can't Place Orders

```bash
# Check credentials
curl -u "$API_USERNAME:$API_PASSWORD" \
  "http://localhost:8000/accounts/master_account/credentials"

# Check balance
curl -X POST "http://localhost:8000/portfolio/balances" \
  -H "Content-Type: application/json" \
  -u "$API_USERNAME:$API_PASSWORD" \
  -d '{"account_name": "master_account", "connector_names": ["binance_perpetual_testnet"]}'

# Check bot logs for errors
docker logs <bot_instance_name> --tail 100
```

## Documentation

- **BOT_DEPLOYMENT_SUCCESS.md** - Complete bot deployment workflow with examples
- **DOCKER_ENV_CONFIG.md** - Detailed .env variable reference
- **ENV_DEPLOYMENT_CHECKLIST.md** - Step-by-step VPS deployment guide
- **CLAUDE.md** - API limitations and workarounds

## Resources

- [Hummingbot Documentation](https://docs.hummingbot.org/)
- [Hummingbot API Docs](https://docs.hummingbot.org/api/)
- [V2 Strategy Framework](https://docs.hummingbot.org/v2-strategies/)
- [Discord Community](https://discord.hummingbot.io/)

## License

Hummingbot is licensed under Apache 2.0.
