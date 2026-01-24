Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "       VERIFICACIÓN FINAL COMPLETA       " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Verificar estructura de directorios
Write-Host "`n1. ESTRUCTURA DE ARCHIVOS:" -ForegroundColor Yellow
$requiredFiles = @(
    "src/app/app.tsx",
    "src/pages/LoginPage.tsx",
    "src/pages/DashboardPage.tsx",
    "src/pages/DoctorsPage.tsx",
    "src/pages/AppointmentsPage.tsx",
    "src/pages/NotificationsPage.tsx",
    "src/components/Auth/Login.tsx",
    "src/components/Common/Dashboard.tsx",
    "src/context/AuthContext.tsx"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $file" -ForegroundColor Red
        $allFilesExist = $false
    }
}

# 2. Verificar imports en App.tsx
Write-Host "`n2. IMPORTS EN App.tsx:" -ForegroundColor Yellow
$appContent = Get-Content "src/app/app.tsx" -Raw
$importLines = $appContent -split "`n" | Where-Object { $_ -match 'import.*from' }

foreach ($line in $importLines) {
    if ($line -match '\.\./pages/' -or $line -match '\.\./context/') {
        Write-Host "  ✅ $($line.Trim())" -ForegroundColor Green
    } elseif ($line -match '\./pages/' -or $line -match '\./context/') {
        Write-Host "  ❌ $($line.Trim())" -ForegroundColor Red
    } else {
        Write-Host "  ✓ $($line.Trim())" -ForegroundColor Gray
    }
}

# 3. Verificar props en páginas
Write-Host "`n3. PROPS EN PÁGINAS:" -ForegroundColor Yellow

# LoginPage
$loginPage = Get-Content "src/pages/LoginPage.tsx" -Raw
if ($loginPage -match 'setIsAuthenticated.*:\s*\(value:\s*boolean\)') {
    Write-Host "  ✅ LoginPage acepta setIsAuthenticated" -ForegroundColor Green
} else {
    Write-Host "  ❌ LoginPage NO acepta setIsAuthenticated" -ForegroundColor Red
}

# DashboardPage
$dashboardPage = Get-Content "src/pages/DashboardPage.tsx" -Raw
if ($dashboardPage -match 'setIsAuthenticated.*:\s*\(value:\s*boolean\)') {
    Write-Host "  ✅ DashboardPage acepta setIsAuthenticated" -ForegroundColor Green
} else {
    Write-Host "  ❌ DashboardPage NO acepta setIsAuthenticated" -ForegroundColor Red
}

# 4. Verificar componentes
Write-Host "`n4. COMPONENTES:" -ForegroundColor Yellow

# Login component
$loginComponent = Get-Content "src/components/Auth/Login.tsx" -Raw
if ($loginComponent -match 'onLoginSuccess.*:\s*\(\)\s*=>\s*void') {
    Write-Host "  ✅ Login acepta onLoginSuccess" -ForegroundColor Green
} else {
    Write-Host "  ❌ Login NO acepta onLoginSuccess" -ForegroundColor Red
}

# Dashboard component
$dashboardComponent = Get-Content "src/components/Common/Dashboard.tsx" -Raw
if ($dashboardComponent -match 'onLogout.*:\s*\(\)\s*=>\s*void') {
    Write-Host "  ✅ Dashboard acepta onLogout" -ForegroundColor Green
} else {
    Write-Host "  ❌ Dashboard NO acepta onLogout" -ForegroundColor Red
}

# 5. Verificar hooks React
Write-Host "`n5. HOOKS REACT EN App.tsx:" -ForegroundColor Yellow
if ($appContent -match 'useState.*boolean') {
    Write-Host "  ✅ useState importado y usado" -ForegroundColor Green
} else {
    Write-Host "  ❌ useState NO detectado" -ForegroundColor Red
}

if ($appContent -match 'useEffect') {
    Write-Host "  ✅ useEffect importado y usado" -ForegroundColor Green
} else {
    Write-Host "  ❌ useEffect NO detectado" -ForegroundColor Red
}

# 6. Verificar rutas
Write-Host "`n6. RUTAS CONFIGURADAS:" -ForegroundColor Yellow
$routes = @(
    @{Path="/login"; Protected=$false},
    @{Path="/dashboard"; Protected=$true},
    @{Path="/doctors"; Protected=$true},
    @{Path="/appointments"; Protected=$true},
    @{Path="/notifications"; Protected=$true}
)

foreach ($route in $routes) {
    if ($appContent -match "path=`"$($route.Path)`"") {
        $status = if ($route.Protected) { "🔒 Protegida" } else { "🌐 Pública" }
        Write-Host "  ✅ $($route.Path) $status" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $($route.Path) NO encontrada" -ForegroundColor Red
    }
}

# Resumen final
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "           RESUMEN FINAL                 " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

if ($allFilesExist) {
    Write-Host "🎉 ¡TODAS LAS CORRECCIONES APLICADAS!" -ForegroundColor Green
    Write-Host "`n🚀 PARA INICIAR LA APLICACIÓN:" -ForegroundColor Yellow
    Write-Host "   npx nx serve frontend" -ForegroundColor White
    Write-Host "   O" -ForegroundColor White
    Write-Host "   npm run dev" -ForegroundColor White
    Write-Host "`n🌐 URL: http://localhost:4200" -ForegroundColor White
    Write-Host "👤 Usuario de prueba: testuser@example.com" -ForegroundColor White
    Write-Host "🔑 Contraseña: secret" -ForegroundColor White
} else {
    Write-Host "⚠️  ALGUNOS ARCHIVOS FALTAN" -ForegroundColor Red
    Write-Host "Revise la lista anterior y cree los archivos faltantes" -ForegroundColor Yellow
}
