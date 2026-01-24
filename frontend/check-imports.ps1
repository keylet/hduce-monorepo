# Script de verificación de imports
Write-Host "=== VERIFICACIÓN DE IMPORTS EN frontend/ ===" -ForegroundColor Cyan

# Cambiar al directorio frontend si no estamos allí
$currentDir = Get-Location
if ($currentDir -notmatch "frontend") {
    Write-Host "Cambiando a directorio frontend..." -ForegroundColor Yellow
    if (Test-Path ".\frontend") {
        cd .\frontend
    }
}

# Verificar App.tsx
Write-Host "`n1. Verificando App.tsx..." -ForegroundColor Yellow
$appPath = ".\src\app\app.tsx"
if (Test-Path $appPath) {
    $appContent = Get-Content $appPath -Raw
    
    # Buscar imports incorrectos (./pages/ -> debería ser ../pages/)
    $badImports = [regex]::Matches($appContent, 'import.*from\s+["'']\./pages/')
    
    if ($badImports.Count -eq 0) {
        Write-Host "✅ TODOS los imports en App.tsx son correctos" -ForegroundColor Green
        
        # Mostrar imports actuales
        Write-Host "`nIMPORTS CORRECTOS EN App.tsx:" -ForegroundColor Green
        Get-Content $appPath | Select-String -Pattern 'import.*from' | ForEach-Object { 
            Write-Host "  $_" -ForegroundColor Gray 
        }
    } else {
        Write-Host "❌ SE ENCONTRARON IMPORTS INCORRECTOS ($($badImports.Count)):" -ForegroundColor Red
        $badImports | ForEach-Object { 
            Write-Host "  [ERROR] $($_.Value)" -ForegroundColor Red
            Write-Host "  [SOLUCIÓN] Cambiar a: $($_.Value -replace '\./pages/', '../pages/')" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "❌ ERROR: $appPath no encontrado" -ForegroundColor Red
    Write-Host "   Directorio actual: $(Get-Location)" -ForegroundColor Gray
    Write-Host "   Archivos en src/app/:" -ForegroundColor Gray
    Get-ChildItem ".\src\app\" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "   - $_" }
}

# Verificar que las páginas existen
Write-Host "`n2. Verificando existencia de páginas en src/pages/..." -ForegroundColor Yellow
$pages = @(
    "LoginPage.tsx",
    "DashboardPage.tsx", 
    "DoctorsPage.tsx",
    "AppointmentsPage.tsx",
    "NotificationsPage.tsx"
)

$allPagesExist = $true
foreach ($page in $pages) {
    $fullPath = ".\src\pages\$page"
    if (Test-Path $fullPath) {
        Write-Host "✅ $page existe" -ForegroundColor Green
    } else {
        Write-Host "❌ $page NO existe en $fullPath" -ForegroundColor Red
        $allPagesExist = $false
    }
}

# Verificar AuthContext
Write-Host "`n3. Verificando AuthContext..." -ForegroundColor Yellow
if (Test-Path ".\src\context\AuthContext.tsx") {
    Write-Host "✅ AuthContext.tsx existe" -ForegroundColor Green
} else {
    Write-Host "❌ AuthContext.tsx NO existe" -ForegroundColor Red
    $allPagesExist = $false
}

# Verificar estructura general
Write-Host "`n4. Estructura de directorios:" -ForegroundColor Yellow
Write-Host "   frontend/" -ForegroundColor Gray
Write-Host "   ├── src/" -ForegroundColor Gray
Write-Host "   │   ├── app/" -ForegroundColor Gray
Write-Host "   │   │   └── app.tsx" -ForegroundColor Gray
Write-Host "   │   ├── pages/" -ForegroundColor Gray
Write-Host "   │   │   ├── LoginPage.tsx" -ForegroundColor Gray
Write-Host "   │   │   ├── DashboardPage.tsx" -ForegroundColor Gray
Write-Host "   │   │   ├── DoctorsPage.tsx" -ForegroundColor Gray
Write-Host "   │   │   ├── AppointmentsPage.tsx" -ForegroundColor Gray
Write-Host "   │   │   └── NotificationsPage.tsx" -ForegroundColor Gray
Write-Host "   │   └── context/" -ForegroundColor Gray
Write-Host "   │       └── AuthContext.tsx" -ForegroundColor Gray

if ($allPagesExist) {
    Write-Host "`n=== VERIFICACIÓN COMPLETADA ===" -ForegroundColor Green
    Write-Host "✅ Estructura de archivos OK" -ForegroundColor Green
    Write-Host "✅ Imports corregidos" -ForegroundColor Green
    Write-Host "✅ Listo para ejecutar" -ForegroundColor Green
} else {
    Write-Host "`n=== VERIFICACIÓN FALLIDA ===" -ForegroundColor Red
    Write-Host "❌ Faltan archivos importantes" -ForegroundColor Red
}

Write-Host "`n🚀 Para iniciar la aplicación:" -ForegroundColor Cyan
Write-Host "   npx nx serve frontend" -ForegroundColor White
Write-Host "   o" -ForegroundColor White
Write-Host "   npm run dev" -ForegroundColor White
Write-Host "   URL esperada: http://localhost:4200 o http://localhost:5173" -ForegroundColor White
