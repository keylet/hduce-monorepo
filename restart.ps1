# restart.ps1 - Restart all services with new configuration
Write-Host "🔄 RESTARTING SERVICES WITH POSTGRESQL" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# 1. Stop previous services
Write-Host "`n[1/4] Stopping previous services..." -ForegroundColor Yellow
docker-compose down

# 2. Rebuild user-service with new dependencies
Write-Host "[2/4] Rebuilding user-service..." -ForegroundColor Yellow
cd backend/user-service
docker build -t user-service-with-db .
cd ../..

# 3. Start services
Write-Host "[3/4] Starting services..." -ForegroundColor Yellow
docker-compose up -d

# 4. Wait and verify
Write-Host "[4/4] Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "`n✅ SERVICES RESTARTED" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

# Check status
docker-compose ps

Write-Host "`n🔍 VERIFICATION:" -ForegroundColor Yellow
Write-Host "1. PostgreSQL: docker exec -it hduce-postgres psql -U hduce_user -d hduce_db -c '\dt'" -ForegroundColor Gray
Write-Host "2. User Service: http://localhost:8001/health" -ForegroundColor Gray
Write-Host "3. Adminer (DB GUI): http://localhost:8080" -ForegroundColor Gray
Write-Host "   - System: PostgreSQL" -ForegroundColor Gray
Write-Host "   - Server: postgres" -ForegroundColor Gray
Write-Host "   - Username: hduce_user" -ForegroundColor Gray
Write-Host "   - Password: hduce_pass" -ForegroundColor Gray
Write-Host "   - Database: hduce_db" -ForegroundColor Gray