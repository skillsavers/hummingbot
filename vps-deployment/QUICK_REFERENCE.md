# Hummingbot VPS Quick Reference

## Deploy

```bash
cd vps-deployment
./deploy.sh
```

## Essential Commands

### Attach to Bot
```bash
ssh root@46.101.135.160 'docker attach hummingbot'
```
Detach: `Ctrl+P` then `Ctrl+Q`

### View Logs
```bash
# Live logs
ssh root@46.101.135.160 'cd /opt/hummingbot && docker compose logs -f hummingbot'

# Last 100 lines
ssh root@46.101.135.160 'cd /opt/hummingbot && docker compose logs --tail=100 hummingbot'
```

### Restart
```bash
ssh root@46.101.135.160 'systemctl restart hummingbot'
```

### Status
```bash
ssh root@46.101.135.160 'systemctl status hummingbot'
ssh root@46.101.135.160 'cd /opt/hummingbot && docker compose ps'
```

### Update
```bash
ssh root@46.101.135.160 'cd /opt/hummingbot && docker compose pull && docker compose up -d'
```

### Stop/Start
```bash
ssh root@46.101.135.160 'systemctl stop hummingbot'
ssh root@46.101.135.160 'systemctl start hummingbot'
```

## File Locations on VPS

- **Config**: `/opt/hummingbot/data/hummingbot/conf/`
- **Logs**: `/opt/hummingbot/data/hummingbot/logs/`
- **Data**: `/opt/hummingbot/data/hummingbot/data/`
- **Compose**: `/opt/hummingbot/docker-compose.yml`
- **Nginx**: `/opt/hummingbot/nginx/`

## Backup

```bash
# Create backup
ssh root@46.101.135.160 'cd /opt/hummingbot && tar -czf ~/hummingbot-backup.tar.gz data/hummingbot'

# Download backup
scp root@46.101.135.160:~/hummingbot-backup.tar.gz ./
```

## Troubleshooting

### Container Issues
```bash
ssh root@46.101.135.160 'cd /opt/hummingbot && docker compose logs hummingbot'
ssh root@46.101.135.160 'docker ps -a'
```

### Restart Everything
```bash
ssh root@46.101.135.160 'systemctl restart docker && systemctl restart hummingbot'
```

### Resource Usage
```bash
ssh root@46.101.135.160 'docker stats --no-stream'
ssh root@46.101.135.160 'df -h'
ssh root@46.101.135.160 'free -h'
```

## Health Checks

```bash
# Container health
ssh root@46.101.135.160 'docker ps --format "table {{.Names}}\t{{.Status}}"'

# Nginx health
curl http://46.101.135.160/health

# Service health
ssh root@46.101.135.160 'systemctl is-active hummingbot'
```

## VPS IP
**46.101.135.160**
