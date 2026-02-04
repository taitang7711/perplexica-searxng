# Deploy script for Perplexica + SearXNG (PowerShell version)
$SERVER = "192.168.0.102"
$USER = "osboxes"
$PORT = "9052"
$REPO_URL = "https://github.com/taitang7711/perplexica-searxng.git"

Write-Host "🚀 Starting deployment to ${SERVER}:${PORT}..." -ForegroundColor Green
Write-Host "📝 Password: vinhtai1511" -ForegroundColor Yellow
Write-Host ""

# Create SSH command script
$sshScript = @"
cd /home/osboxes && \
mkdir -p perplexica-deploy && \
cd perplexica-deploy && \
echo '🔄 Pulling latest code...' && \
if [ -d '.git' ]; then git pull origin master; else git clone $REPO_URL .; fi && \
echo '🐳 Stopping existing containers...' && \
docker stop perplexica-app perplexica-searxng 2>/dev/null || true && \
docker rm perplexica-app perplexica-searxng 2>/dev/null || true && \
echo '🔍 Starting SearXNG container...' && \
docker run -d --name perplexica-searxng --network host -v \$(pwd)/searxng:/etc/searxng:rw --restart unless-stopped searxng/searxng:latest && \
sleep 10 && \
echo '🏗️ Building Perplexica...' && \
docker build -t perplexica-custom . && \
echo '🚀 Starting Perplexica container...' && \
docker run -d --name perplexica-app --network host -v \$(pwd)/data:/home/perplexica/data -e PORT=9052 -e SEARXNG_API_URL=http://localhost:8080 --restart unless-stopped perplexica-custom && \
sleep 15 && \
echo '🧪 Testing services...' && \
curl -s http://localhost:8080/search?q=test\&format=json | head -c 100 && \
echo '' && \
curl -s http://localhost:9052 | head -c 100 && \
echo '' && \
echo '✅ Deployment completed!' && \
docker ps | grep perplexica
"@

# Execute via SSH
Write-Host "Connecting to server via SSH..." -ForegroundColor Yellow
Write-Host "Please enter password when prompted: vinhtai1511" -ForegroundColor Cyan
Write-Host ""

ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} $sshScript

Write-Host ""
Write-Host "🎉 Remote deployment finished!" -ForegroundColor Green
Write-Host "🌐 Access Perplexica at: http://${SERVER}:${PORT}" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testing from local machine..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "http://${SERVER}:${PORT}" -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ Perplexica is responding! Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "✅ All done! Perplexica is running on http://${SERVER}:${PORT}" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not reach Perplexica from local machine. Check firewall settings." -ForegroundColor Yellow
    Write-Host "   But deployment on server should be complete. Try accessing from server network." -ForegroundColor Yellow
}
