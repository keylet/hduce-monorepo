Write-Host "=== VERIFICACIÓN RÁPIDA ===" -ForegroundColor Cyan

# Archivos críticos
$files = @(
    "src/app/app.tsx",
    "src/pages/LoginPage.tsx", 
    "src/pages/DashboardPage.tsx",
    "src/pages/DoctorsPage.tsx",
    "src/pages/AppointmentsPage.tsx",
    "src/pages/NotificationsPage.tsx"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content $file -First 1
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file" -ForegroundColor Red
    }
}

# Verificar imports
Write-Host "`n=== IMPORTS EN App.tsx ===" -ForegroundColor Yellow
$appImports = Get-Content "src/app/app.tsx" | Select-String -Pattern 'import.*from.*pages'
if ($appImports -match '\.\./pages/') {
    Write-Host "✅ Todos los imports son ../pages/" -ForegroundColor Green
} else {
    Write-Host "❌ Hay imports incorrectos" -ForegroundColor Red
    $appImports
}
