#!/bin/bash
# SSL Certificate Renewal Script for Upskillo

# Stop frontend to free port 80
docker stop upskillo-frontend-1

# Renew certificate
certbot renew --quiet

# Start frontend
docker start upskillo-frontend-1

echo "$(date): Certificate renewal completed"
