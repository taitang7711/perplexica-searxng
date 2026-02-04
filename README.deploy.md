# Deployment Guide

## Quick Deploy

### Using PowerShell (Windows)
```powershell
.\deploy.ps1
```

### Using Bash (Linux/Mac)
```bash
chmod +x deploy.sh
./deploy.sh
```

## Server Information
- **Server**: 192.168.0.102
- **User**: osboxes
- **Port**: 9052
- **Network**: host mode

## Manual Deployment

If you prefer to deploy manually:

```bash
# SSH to server
ssh osboxes@192.168.0.102

# Clone repository
cd ~
mkdir -p perplexica-deploy
cd perplexica-deploy
git clone https://github.com/taitang7711/perplexica-searxng.git .

# Deploy with Docker Compose
docker-compose -f docker-compose.deploy.yaml down
docker-compose -f docker-compose.deploy.yaml up -d --build

# Check status
docker ps
```

## Access
After deployment, access Perplexica at:
- **URL**: http://192.168.0.102:9052

## Troubleshooting

### Check container logs
```bash
docker logs perplexica-app
docker logs perplexica-searxng
```

### Restart services
```bash
docker restart perplexica-app perplexica-searxng
```

### Test SearXNG
```bash
curl http://localhost:8080/search?q=test&format=json
```

### Test Perplexica
```bash
curl http://localhost:9052
```
