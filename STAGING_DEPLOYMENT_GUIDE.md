# Upskillo Staging Environment Deployment Guide

## Domain Configuration

**Staging Domain**: `staging.upskillo.opcito.com`

### DNS Configuration (For Admin)

Please configure the following DNS record:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | staging.upskillo.opcito.com | 13.235.168.150 | 300 |

**EC2 Public IP**: `13.235.168.150`

---

## Infrastructure Details

| Resource | Value |
|----------|-------|
| **EC2 Instance** | i-08039c8fce6b51cae |
| **EC2 Public IP** | 13.235.168.150 |
| **Instance Type** | t3.micro |
| **Region** | ap-south-1 |
| **RDS Endpoint** | upskillo-staging-env-mysql-restored.cukwnuzu8fg8.ap-south-1.rds.amazonaws.com:3306 |
| **Database Name** | upskillo_staging |
| **VPC CIDR** | 10.30.0.0/16 |

---

## SSH Access

```bash
# Connect to staging server (only from office IP: 27.107.60.186)
ssh -i upskillo-staging-2026.pem ubuntu@13.235.168.150
```

---

## Manual Deployment Steps

### 1. Connect to Staging Server

```bash
ssh -i upskillo-staging-2026.pem ubuntu@13.235.168.150
```

### 2. Clone/Update Repository

```bash
cd /opt
sudo git clone https://github.com/opcitotech/rise-together-app.git upskillo-staging || true
cd /opt/upskillo-staging
sudo git fetch origin Upskillo-Prod-2026
sudo git checkout Upskillo-Prod-2026
sudo git pull origin Upskillo-Prod-2026
```

### 3. Create Backend Environment File

```bash
sudo cat > /opt/upskillo-staging/BE/.env.staging << 'EOF'
# Database Configuration - Staging RDS
DB_USER=upskilloadmin
DB_PASSWORD=StagingUpskillo2026Secure
DB_HOST=upskillo-staging-env-mysql-restored.cukwnuzu8fg8.ap-south-1.rds.amazonaws.com
DB_PORT=3306
DB_NAME=upskillo_staging

# Environment
ENVIRONMENT=staging
DEBUG=true
EOF
```

### 4. Obtain SSL Certificate (After DNS is configured)

```bash
# Install certbot if not installed
sudo apt-get update
sudo apt-get install -y certbot

# Create webroot directory
sudo mkdir -p /var/www/certbot

# Obtain certificate
sudo certbot certonly --standalone \
    -d staging.upskillo.opcito.com \
    --email admin@opcito.com \
    --agree-tos \
    --non-interactive
```

### 5. Deploy Application

```bash
cd /opt/upskillo-staging

# Stop existing containers
sudo docker compose -f docker-compose.staging.yml down || true

# Build and start
sudo docker compose -f docker-compose.staging.yml up -d --build

# Check status
sudo docker compose -f docker-compose.staging.yml ps
```

### 6. Verify Deployment

```bash
# Check container logs
sudo docker compose -f docker-compose.staging.yml logs -f

# Test backend
curl http://localhost:4000/api/health

# Test frontend (after SSL)
curl -I https://staging.upskillo.opcito.com
```

---

## SSL Certificate Renewal

SSL certificates from Let's Encrypt expire every 90 days. Set up auto-renewal:

```bash
# Add to crontab
sudo crontab -e

# Add this line:
0 0 1 * * certbot renew --quiet && docker compose -f /opt/upskillo-staging/docker-compose.staging.yml restart frontend
```

---

## Configuration Files (Staging-Specific)

| File | Purpose |
|------|---------|
| `docker-compose.staging.yml` | Staging Docker Compose configuration |
| `BE/.env.staging` | Backend environment variables for staging |
| `FE/Dockerfile.staging` | Frontend Dockerfile for staging |
| `FE/nginx.staging.conf` | Nginx configuration with staging domain |

---

## Security Features

The staging environment includes:

- **fail2ban**: SSH brute force protection
- **UFW Firewall**: Only ports 22, 80, 443 open
- **SSH Hardening**: Key-only auth, no root login
- **Kernel Hardening**: SYN flood protection
- **SSL/TLS**: Let's Encrypt certificate with strong ciphers
- **Security Headers**: X-Frame-Options, X-Content-Type-Options, etc.

---

## Troubleshooting

### Check Container Status
```bash
sudo docker compose -f docker-compose.staging.yml ps
```

### View Logs
```bash
# All services
sudo docker compose -f docker-compose.staging.yml logs -f

# Backend only
sudo docker compose -f docker-compose.staging.yml logs -f backend

# Frontend only
sudo docker compose -f docker-compose.staging.yml logs -f frontend
```

### Restart Services
```bash
sudo docker compose -f docker-compose.staging.yml restart
```

### Database Connection Test
```bash
# From EC2 instance
mysql -h upskillo-staging-env-mysql-restored.cukwnuzu8fg8.ap-south-1.rds.amazonaws.com \
      -u upskilloadmin \
      -p'StagingUpskillo2026Secure' \
      upskillo_staging
```

---

## Differences from Production

| Aspect | Production | Staging |
|--------|------------|---------|
| Domain | upskillo.opcito.com | staging.upskillo.opcito.com |
| EC2 Type | t3.medium | t3.micro |
| RDS Type | db.t3.small | db.t3.micro |
| Database | upskillo | upskillo_staging |
| SSH Key | Upskillo-2026.pem | upskillo-staging-2026.pem |
| VPC CIDR | 10.20.0.0/16 | 10.30.0.0/16 |
