#!/bin/bash

# Deploy script for Perplexica + SearXNG
SERVER="192.168.0.102"
USER="osboxes"
PASSWORD="vinhtai1511"
PORT="9052"
REPO_URL="https://github.com/taitang7711/perplexica-searxng.git"
DEPLOY_DIR="/home/osboxes/perplexica-deploy"

echo "🚀 Starting deployment to $SERVER:$PORT..."

# SSH and deploy
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
    set -e
    
    echo "📦 Setting up deployment directory..."
    mkdir -p /home/osboxes/perplexica-deploy
    cd /home/osboxes/perplexica-deploy
    
    echo "🔄 Pulling latest code..."
    if [ -d ".git" ]; then
        git pull origin master
    else
        git clone https://github.com/taitang7711/perplexica-searxng.git .
    fi
    
    echo "🐳 Stopping existing containers..."
    docker stop perplexica-app 2>/dev/null || true
    docker stop perplexica-searxng 2>/dev/null || true
    docker rm perplexica-app 2>/dev/null || true
    docker rm perplexica-searxng 2>/dev/null || true
    
    echo "🔍 Starting SearXNG container..."
    docker run -d \
        --name perplexica-searxng \
        --network host \
        -v $(pwd)/searxng:/etc/searxng:rw \
        --restart unless-stopped \
        searxng/searxng:latest
    
    echo "⏳ Waiting for SearXNG to be ready..."
    sleep 10
    
    echo "🏗️ Building Perplexica..."
    docker build -t perplexica-custom .
    
    echo "🚀 Starting Perplexica container..."
    docker run -d \
        --name perplexica-app \
        --network host \
        -v $(pwd)/data:/home/perplexica/data \
        -e PORT=9052 \
        -e SEARXNG_API_URL=http://localhost:8080 \
        --restart unless-stopped \
        perplexica-custom
    
    echo "⏳ Waiting for services to start..."
    sleep 15
    
    echo "🧪 Testing SearXNG..."
    curl -s http://localhost:8080/search?q=test&format=json | head -c 100
    
    echo ""
    echo "🧪 Testing Perplexica..."
    curl -s http://localhost:9052 | head -c 100
    
    echo ""
    echo "✅ Deployment completed!"
    echo "📊 Container status:"
    docker ps | grep perplexica
    
ENDSSH

echo ""
echo "🎉 Remote deployment finished!"
echo "🌐 Access Perplexica at: http://192.168.0.102:9052"
echo ""
echo "Testing from local machine..."
curl -s "http://192.168.0.102:9052" | head -c 100
echo ""
echo "✅ All done! Perplexica is running on http://192.168.0.102:9052"
