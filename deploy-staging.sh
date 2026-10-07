#!/bin/bash
# =============================================================================
# STAGING DEPLOYMENT SCRIPT
# Domain: staging.upskillo.opcito.com
# =============================================================================

set -e

DOMAIN="staging.upskillo.opcito.com"
EMAIL="admin@opcito.com"  # Change to your email for Let's Encrypt notifications

echo "=========================================="
echo "Upskillo Staging Deployment"
echo "Domain: $DOMAIN"
echo "=========================================="

# Step 1: Stop existing containers
echo ">>> Stopping existing containers..."
docker compose -f docker-compose.staging.yml down || true

# Step 2: Check if SSL certificate exists
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo ">>> SSL certificate not found. Obtaining certificate..."
    
    # Create temporary nginx config for ACME challenge
    cat > /tmp/nginx-acme.conf << 'EOF'
events {
    worker_connections 1024;
}
http {
    server {
        listen 80;
        server_name staging.upskillo.opcito.com;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            return 200 'Staging server - SSL setup in progress';
            add_header Content-Type text/plain;
        }
    }
}
EOF

    # Create certbot webroot directory
    mkdir -p /var/www/certbot

    # Start temporary nginx for ACME challenge
    docker run -d --name nginx-acme \
        -p 80:80 \
        -v /tmp/nginx-acme.conf:/etc/nginx/nginx.conf:ro \
        -v /var/www/certbot:/var/www/certbot \
        nginx:stable-alpine

    # Wait for nginx to start
    sleep 5

    # Obtain SSL certificate
    certbot certonly --webroot \
        -w /var/www/certbot \
        -d $DOMAIN \
        --email $EMAIL \
        --agree-tos \
        --non-interactive

    # Stop temporary nginx
    docker stop nginx-acme && docker rm nginx-acme

    echo ">>> SSL certificate obtained successfully!"
else
    echo ">>> SSL certificate already exists."
fi

# Step 3: Build and start containers
echo ">>> Building and starting staging containers..."
docker compose -f docker-compose.staging.yml up -d --build

# Step 4: Wait for services to be healthy
echo ">>> Waiting for services to start..."
sleep 10

# Step 5: Check service status
echo ">>> Checking service status..."
docker compose -f docker-compose.staging.yml ps

echo "=========================================="
echo "Staging deployment complete!"
echo "URL: https://$DOMAIN"
echo "=========================================="
