#!/bin/bash
set -e

echo "📦 Setting up deployment directory..."
mkdir -p ~/perplexica-deploy
cd ~/perplexica-deploy

echo "🔄 Pulling latest code..."
if [ -d ".git" ]; then
    git pull origin master
else
    git clone https://github.com/taitang7711/perplexica-searxng.git .
fi

echo "🐳 Stopping existing SearXNG container..."
docker stop perplexica-searxng 2>/dev/null || true
docker rm perplexica-searxng 2>/dev/null || true

echo "🔍 Starting SearXNG container..."
docker run -d \
    --name perplexica-searxng \
    --network host \
    -v $(pwd)/searxng:/etc/searxng:rw \
    --restart unless-stopped \
    searxng/searxng:latest

echo "⏳ Waiting for SearXNG..."
sleep 10

echo "📦 Installing Node.js dependencies..."
# Install nvm if not exists
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js 20
nvm install 20
nvm use 20

# Install yarn if not exists
npm install -g yarn pm2

echo "🏗️ Installing dependencies..."
yarn install

echo "🔧 Building Perplexica..."
yarn build

echo "🛑 Stopping existing PM2 process..."
pm2 stop perplexica 2>/dev/null || true
pm2 delete perplexica 2>/dev/null || true

echo "🚀 Starting Perplexica with PM2..."
PORT=9052 pm2 start yarn --name "perplexica" -- start

echo "💾 Saving PM2 process list..."
pm2 save

echo "⏳ Waiting for services..."
sleep 10

echo ""
echo "🧪 Testing SearXNG..."
curl -s "http://localhost:8888/search?q=test&format=json" | head -c 100

echo ""
echo "🧪 Testing Perplexica..."
curl -s http://localhost:9052 | head -c 100

echo ""
echo "✅ Deployment completed!"
echo ""
echo "📊 SearXNG Docker status:"
docker ps | grep searxng
echo ""
echo "📊 Perplexica PM2 status:"
pm2 status
