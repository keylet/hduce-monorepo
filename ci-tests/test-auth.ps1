param(
    [string]$ProjectRoot = "C:\Users\raich\Desktop\hduce-monorepo"
)

# Cargar la función primero
. "C:\Users\raich\Desktop\hduce-monorepo\ci-tests\Invoke-SafeWebRequest.ps1"

Write-Host "🔐 HDuce Authentication Tests" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# 1. Test de login directo
Write-Host "`n1. LOGIN TEST:" -ForegroundColor Yellow

$loginData = @{
    email = "testuser@example.com"
    password = "secret"
} | ConvertTo-Json

Write-Host "  Testing login at http://localhost:8000/auth/login..." -ForegroundColor Gray

$result = Invoke-SafeWebRequest -Uri "http://localhost:8000/auth/login" -Method POST -Body $loginData -Timeout 5000

if ($result -and $result.Success -and $result.StatusCode -eq 200) {
    try {
        $tokenData = $result.Content | ConvertFrom-Json
        Write-Host "  ✅ Login successful" -ForegroundColor Green
        Write-Host "     Token: $($tokenData.access_token.Substring(0, 30))..." -ForegroundColor Gray
        Write-Host "     Type: $($tokenData.token_type)" -ForegroundColor Gray
        
        # Guardar nuevo token
        $newTokenFile = "$ProjectRoot\new-token-from-test.txt"
        $tokenData.access_token | Out-File -FilePath $newTokenFile -Encoding UTF8
        Write-Host "     New token saved to: $newTokenFile" -ForegroundColor Gray
    } catch {
        Write-Host "  ⚠️  Login response format unexpected: $($result.Content)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ❌ Login failed: HTTP $($result.StatusCode)" -ForegroundColor Red
    if ($result.Content) {
        Write-Host "     Response: $($result.Content)" -ForegroundColor Gray
    }
}

# 2. Test de token existente
Write-Host "`n2. EXISTING TOKEN VALIDATION:" -ForegroundColor Yellow

$tokenFile = "$ProjectRoot\new-token.txt"
if (Test-Path $tokenFile) {
    $existingToken = (Get-Content $tokenFile -First 1).Trim()
    Write-Host "  Found token file: $tokenFile" -ForegroundColor Gray
    Write-Host "  Token preview: $($existingToken.Substring(0, 30))..." -ForegroundColor Gray
    
    $headers = @{
        "Authorization" = "Bearer $existingToken"
    }
    
    Write-Host "  Testing token at http://localhost:8000/auth/verify-token..." -ForegroundColor Gray
    
    $result = Invoke-SafeWebRequest -Uri "http://localhost:8000/auth/verify-token" -Method GET -Headers $headers -Timeout 3000
    
    if ($result -and $result.Success -and $result.StatusCode -eq 200) {
        Write-Host "  ✅ Existing token is valid" -ForegroundColor Green
        Write-Host "     Response: $($result.Content)" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ Existing token is INVALID or endpoint not found" -ForegroundColor Red
        Write-Host "     HTTP Status: $($result.StatusCode)" -ForegroundColor Gray
        Write-Host "     Error: $($result.Exception)" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠️  No existing token file found at: $tokenFile" -ForegroundColor Yellow
}

# 3. Probar endpoints protegidos con el token
Write-Host "`n3. PROTECTED ENDPOINTS TEST:" -ForegroundColor Yellow

if (Test-Path $tokenFile) {
    $existingToken = (Get-Content $tokenFile -First 1).Trim()
    $authHeaders = @{
        "Authorization" = "Bearer $existingToken"
        "Content-Type" = "application/json"
    }
    
    $endpoints = @(
        @{Name="Appointments"; Url="http://localhost/api/appointments/"},
        @{Name="Notifications"; Url="http://localhost/api/notifications/"},
        @{Name="Users"; Url="http://localhost/api/v1/users/"}
    )
    
    foreach ($endpoint in $endpoints) {
        Write-Host "  Testing $($endpoint.Name)..." -ForegroundColor Gray
        $result = Invoke-SafeWebRequest -Uri $endpoint.Url -Method GET -Headers $authHeaders -Timeout 5000
        
        if ($result -and $result.Success) {
            if ($result.StatusCode -eq 200) {
                Write-Host "    ✅ $($endpoint.Name) - HTTP 200 (Success)" -ForegroundColor Green
            } elseif ($result.StatusCode -eq 401 -or $result.StatusCode -eq 403) {
                Write-Host "    ❌ $($endpoint.Name) - HTTP $($result.StatusCode) (Authentication failed)" -ForegroundColor Red
            } else {
                Write-Host "    ⚠️  $($endpoint.Name) - HTTP $($result.StatusCode)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "    ❌ $($endpoint.Name) - Failed: $($result.Exception)" -ForegroundColor Red
        }
        
        Start-Sleep -Milliseconds 500
    }
}

Write-Host "`n✅ Authentication tests completed" -ForegroundColor Green
