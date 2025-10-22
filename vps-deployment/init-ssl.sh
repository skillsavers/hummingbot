#!/bin/bash
set -e

DOMAIN="hummingbot.skillsavers.ai"
EMAIL="your-email@example.com"  # Change this!

echo "🔒 Initializing SSL certificates for $DOMAIN"
echo ""

# Check if certificates already exist
if [ -d "./data/certbot/conf/live/$DOMAIN" ]; then
    echo "⚠️  Certificates already exist for $DOMAIN"
    echo "To renew, use: docker-compose exec certbot certbot renew"
    exit 0
fi

# Create required directories
echo "📁 Creating required directories..."
mkdir -p ./data/certbot/conf
mkdir -p ./data/certbot/www

echo ""
echo "🚀 Starting nginx for ACME challenge..."
docker-compose up -d nginx

echo ""
echo "⏳ Waiting for nginx to be ready..."
sleep 5

echo ""
echo "📜 Requesting SSL certificate from Let's Encrypt..."
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SSL certificate obtained successfully!"
    echo ""
    echo "🔄 Reloading nginx with SSL configuration..."
    docker-compose restart nginx
    
    echo ""
    echo "✅ Done! Your site should now be accessible at:"
    echo "   https://$DOMAIN"
    echo ""
    echo "📋 Service endpoints:"
    echo "   - Dashboard: https://$DOMAIN/dashboard"
    echo "   - API:       https://$DOMAIN/api/docs"
    echo "   - Broker:    https://$DOMAIN/broker/"
else
    echo ""
    echo "❌ Failed to obtain SSL certificate"
    echo "Please check:"
    echo "  1. DNS record for $DOMAIN points to this server"
    echo "  2. Port 80 is accessible from the internet"
    echo "  3. Email address is correct in this script"
    exit 1
fi
