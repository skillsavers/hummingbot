# Hummingbot VPS Production Deployment

Production-ready deployment package for Hummingbot trading bot with Nginx reverse proxy, automatic restarts, and monitoring capabilities.

## Features

- **Docker Compose** orchestration for easy management
- **Nginx** reverse proxy (ready for API exposure and SSL)
- **Automatic restarts** via systemd service
- **Automatic updates** with Watchtower (checks hourly)
- **Log rotation** (10MB max per file, 5 files retained)
- **Health checks** for container monitoring
- **Persistent data** storage
- **Production-ready** security headers and rate limiting

## Quick Start

### Prerequisites

1. A VPS with SSH access (tested with Ubuntu/Debian)
2. SSH key authentication set up
3. User with sudo/root privileges
4. GitHub Personal Access Token (if using private images) - see [GITHUB_AUTH.md](GITHUB_AUTH.md)

### 1. Set Up SSH Access (if not already done)

```bash
ssh-copy-id root@46.101.135.160
```

### 2. Set Up GitHub Authentication (for private images)

If your Docker image is private, set your GitHub credentials:

```bash
export GITHUB_USERNAME="your_github_username"
export GITHUB_TOKEN="ghp_your_token_here"
```

See [GITHUB_AUTH.md](GITHUB_AUTH.md) for detailed instructions on creating a GitHub Personal Access Token.

### 3. Deploy to VPS

Simply run the deployment script:

```bash
cd vps-deployment
./deploy.sh
```

The script will:
- Install Docker and Docker Compose (if needed)
- Transfer configuration files
- Set up systemd service
- Start all containers
- Configure automatic restarts

### 4. Verify Deployment

```bash
ssh root@46.101.135.160 'docker compose -f /opt/hummingbot/docker-compose.yml ps'
```

## File Structure

```
vps-deployment/
├── deploy.sh                    # Main deployment script
├── docker-compose.yml           # Docker Compose configuration
├── nginx/
│   ├── nginx.conf              # Main Nginx configuration
│   ├── conf.d/
│   │   └── default.conf        # Server blocks and routing
│   └── ssl/                    # Place SSL certificates here
└── README.md                    # This file
```

After deployment on VPS:
```
/opt/hummingbot/
├── docker-compose.yml
├── nginx/
│   ├── nginx.conf
│   ├── conf.d/
│   └── ssl/
└── data/
    ├── hummingbot/
    │   ├── conf/               # Bot configuration
    │   ├── data/               # Bot data
    │   ├── logs/               # Bot logs
    │   ├── certs/              # Certificates
    │   ├── scripts/            # Custom scripts
    │   └── controllers/        # Controllers
    └── nginx/
        ├── cache/              # Nginx cache
        └── logs/               # Nginx logs
```

## Common Operations

### Attach to Hummingbot Console

```bash
ssh root@46.101.135.160 'docker attach hummingbot'
```

**Important**: Use `Ctrl+P` followed by `Ctrl+Q` to detach without stopping the container.

### View Logs

```bash
# Hummingbot logs
ssh root@46.101.135.160 'cd /opt/hummingbot && docker compose logs -f hummingbot'

# Nginx logs
ssh root@46.101.135.160 'cd /opt/hummingbot && docker compose logs -f nginx'

# All logs
ssh root@46.101.135.160 'cd /opt/hummingbot && docker compose logs -f'
```

### Restart Services

```bash
# Via systemd (recommended)
ssh root@46.101.135.160 'systemctl restart hummingbot'

# Via docker compose
ssh root@46.101.135.160 'cd /opt/hummingbot && docker compose restart'
```

### Update to Latest Version

Watchtower automatically checks for updates every hour. To manually update:

```bash
ssh root@46.101.135.160 'cd /opt/hummingbot && docker compose pull && docker compose up -d'
```

### Stop Services

```bash
ssh root@46.101.135.160 'systemctl stop hummingbot'
```

### Start Services

```bash
ssh root@46.101.135.160 'systemctl start hummingbot'
```

### Check Status

```bash
# Container status
ssh root@46.101.135.160 'cd /opt/hummingbot && docker compose ps'

# Service status
ssh root@46.101.135.160 'systemctl status hummingbot'

# Health check
curl http://46.101.135.160/health
```

## Configuration

### Environment Variables

You can customize the deployment by setting these environment variables before running `deploy.sh`:

```bash
export VPS_HOST="your-vps-ip"
export VPS_USER="your-username"
./deploy.sh
```

### Nginx Configuration

Edit `nginx/conf.d/default.conf` to:
- Add SSL/HTTPS configuration
- Expose Hummingbot Gateway API
- Add custom domains
- Configure additional services

After making changes, redeploy or restart nginx:

```bash
ssh root@46.101.135.160 'cd /opt/hummingbot && docker compose restart nginx'
```

## SSL/HTTPS Setup

### Using Let's Encrypt (Recommended)

1. SSH into your VPS:
   ```bash
   ssh root@46.101.135.160
   ```

2. Install certbot:
   ```bash
   apt-get update
   apt-get install -y certbot
   ```

3. Get certificate (replace with your domain):
   ```bash
   certbot certonly --standalone -d yourdomain.com
   ```

4. Copy certificates:
   ```bash
   cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem /opt/hummingbot/nginx/ssl/
   cp /etc/letsencrypt/live/yourdomain.com/privkey.pem /opt/hummingbot/nginx/ssl/
   ```

5. Uncomment HTTPS configuration in `nginx/conf.d/default.conf`

6. Restart nginx:
   ```bash
   cd /opt/hummingbot && docker compose restart nginx
   ```

### Auto-renewal

Add to crontab:
```bash
0 0 * * * certbot renew --quiet && cp /etc/letsencrypt/live/yourdomain.com/*.pem /opt/hummingbot/nginx/ssl/ && cd /opt/hummingbot && docker compose restart nginx
```

## Monitoring

### Check Container Health

```bash
ssh root@46.101.135.160 'docker ps --filter health=healthy'
```

### View Resource Usage

```bash
ssh root@46.101.135.160 'docker stats'
```

### Check Nginx Status

```bash
ssh root@46.101.135.160 'curl http://localhost/nginx-status'
```

## Troubleshooting

### Containers won't start

```bash
# Check logs
ssh root@46.101.135.160 'cd /opt/hummingbot && docker compose logs'

# Check Docker service
ssh root@46.101.135.160 'systemctl status docker'

# Restart everything
ssh root@46.101.135.160 'systemctl restart docker && systemctl restart hummingbot'
```

### Can't connect to VPS

```bash
# Test SSH connection
ssh -v root@46.101.135.160

# Ensure SSH key is added
ssh-add -l
ssh-copy-id root@46.101.135.160
```

### Port conflicts

If ports 80 or 443 are already in use:

```bash
# Check what's using the port
ssh root@46.101.135.160 'ss -tlnp | grep :80'

# Stop conflicting service
ssh root@46.101.135.160 'systemctl stop apache2'  # Example
```

## Security Recommendations

1. **Change default SSH port** (edit `/etc/ssh/sshd_config`)
2. **Set up firewall**:
   ```bash
   ufw allow 22/tcp
   ufw allow 80/tcp
   ufw allow 443/tcp
   ufw enable
   ```
3. **Enable SSL/HTTPS** (see SSL setup section)
4. **Regular updates**:
   ```bash
   ssh root@46.101.135.160 'apt-get update && apt-get upgrade -y'
   ```
5. **Monitor logs** regularly for suspicious activity
6. **Use strong passwords** for Hummingbot configuration

## Backup

### Backup Hummingbot Data

```bash
ssh root@46.101.135.160 'cd /opt/hummingbot && tar -czf hummingbot-backup-$(date +%Y%m%d).tar.gz data/hummingbot'

scp root@46.101.135.160:/opt/hummingbot/hummingbot-backup-*.tar.gz ./backups/
```

### Restore from Backup

```bash
scp ./backups/hummingbot-backup-YYYYMMDD.tar.gz root@46.101.135.160:/opt/hummingbot/

ssh root@46.101.135.160 'cd /opt/hummingbot && tar -xzf hummingbot-backup-YYYYMMDD.tar.gz && systemctl restart hummingbot'
```

## Support

- Hummingbot Documentation: https://docs.hummingbot.org/
- GitHub: https://github.com/skillsavers/hummingbot
- Discord: https://discord.hummingbot.io/

## License

This deployment configuration is provided as-is. Hummingbot is licensed under Apache 2.0.
