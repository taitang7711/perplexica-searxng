# Deploy Perplexica to Server
# Password: vinhtai1511

Write-Host "🚀 Starting deployment to 192.168.0.102:9052..." -ForegroundColor Green
Write-Host "📝 Password: vinhtai1511" -ForegroundColor Yellow
Write-Host ""

# Connect and deploy
ssh osboxes@192.168.0.102 "bash -s" << 'REMOTESCRIPT'
    set -e
    
    echo "📦 Setting up deployment directory..."
    cd /home/osboxes
    mkdir -p perplexica-deploy
    cd perplexica-deploy
    
    echo "🔄 Pulling latest code..."
    if [ -d ".git" ]; then
        git pull origin master
    else
        git clone https://github.com/taitang7711/perplexica-searxng.git .
    fi
    
    echo "🐳 Stopping existing containers..."
    docker stop perplexica-app perplexica-searxng 2>/dev/null || true
    docker rm perplexica-app perplexica-searxng 2>/dev/null || true
    
    echo "🔍 Starting SearXNG container..."
    docker run -d \
        --name perplexica-searxng \
        --network host \
        -v $(pwd)/searxng:/etc/searxng:rw \
        --restart unless-stopped \
        searxng/searxng:latest
    
    echo "⏳ Waiting for SearXNG..."
    sleep 10
    
    echo "🏗️ Building Perplexica..."
    docker build -t perplexica-custom .
    
    echo "🚀 Starting Perplexica..."
    docker run -d \
        --name perplexica-app \
        --network host \
        -v $(pwd)/data:/home/perplexica/data \
        -e PORT=9052 \
        -e SEARXNG_API_URL=http://localhost:8080 \
        --restart unless-stopped \
        perplexica-custom
    
    echo "⏳ Waiting for services..."
    sleep 15
    
    echo "🧪 Testing SearXNG..."
    curl -s "http://localhost:8080/search?q=test&format=json" | head -c 100
    echo ""
    
    echo "🧪 Testing Perplexica..."
    curl -s http://localhost:9052 | head -c 100
    echo ""
    
    echo "✅ Deployment completed!"
    docker ps | grep perplexica
REMOTESCRIPT

Write-Host ""
Write-Host "🎉 Deployment finished!" -ForegroundColor Green
Write-Host "🌐 Access: http://192.168.0.102:9052" -ForegroundColor Cyan
