# ci-tests\auth-login.ps1
# Obtiene token JWT y lo guarda para usar en tests

param(
    [string]$ProjectRoot = "C:\Users\raich\Desktop\hduce-monorepo",
    [string]$Email = "testuser@example.com",
    [string]$Password = "secret",
    [switch]$ForceRefresh = $false
)

Write-Host "🔐 HDuce Authentication" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan

# Cargar función HTTP
. "$PSScriptRoot\Invoke-SafeWebRequest.ps1"

$tokenFile = "$ProjectRoot\token.txt"
$backupTokenFile = "$ProjectRoot\new-token.txt" # Token existente

# 1. Verificar si ya existe token válido
if ((Test-Path $tokenFile) -and -not $ForceRefresh) {
    $existingToken = (Get-Content $tokenFile -First 1).Trim()
    
    # Probar si el token aún es válido
    $headers = @{ "Authorization" = "Bearer $existingToken" }
    $result = Invoke-SafeWebRequest -Uri "http://localhost:8000/auth/verify" -Method "GET" -Headers $headers -Timeout 3000
    
    if ($result.Success -and $result.StatusCode -eq 200) {
        Write-Host "✅ Using existing valid token" -ForegroundColor Green
        Write-Host "   Token: $($existingToken.Substring(0, 30))..." -ForegroundColor Gray
        return $existingToken
    } else {
        Write-Host "⚠️  Existing token expired or invalid" -ForegroundColor Yellow
    }
}

# 2. Si hay token de backup, probarlo
if (Test-Path $backupTokenFile) {
    $backupToken = (Get-Content $backupTokenFile -First 1).Trim()
    $headers = @{ "Authorization" = "Bearer $backupToken" }
    $result = Invoke-SafeWebRequest -Uri "http://localhost:8000/auth/verify" -Method "GET" -Headers $headers -Timeout 3000
    
    if ($result.Success -and $result.StatusCode -eq 200) {
        $backupToken | Out-File -FilePath $tokenFile -Encoding UTF8
        Write-Host "✅ Using backup token" -ForegroundColor Green
        Write-Host "   Token: $($backupToken.Substring(0, 30))..." -ForegroundColor Gray
        return $backupToken
    }
}

# 3. Hacer login para obtener nuevo token
Write-Host "🔑 Logging in as: $Email" -ForegroundColor Yellow

$loginData = @{
    email = $Email
    password = $Password
} | ConvertTo-Json

$result = Invoke-SafeWebRequest -Uri "http://localhost:8000/auth/login" -Method "POST" -Body $loginData -Timeout 5000

if (-not $result.Success -or $result.StatusCode -ne 200) {
    Write-Host "❌ Login failed: HTTP $($result.StatusCode)" -ForegroundColor Red
    if ($result.Content) {
        Write-Host "   Error: $($result.Content)" -ForegroundColor Gray
    }
    exit 1
}

# Extraer token de respuesta
try {
    $responseData = $result.Content | ConvertFrom-Json
    $newToken = $responseData.access_token
    
    if (-not $newToken) {
        throw "No access_token in response"
    }
    
    # Guardar token
    $newToken | Out-File -FilePath $tokenFile -Encoding UTF8
    Write-Host "✅ New token obtained and saved to: $tokenFile" -ForegroundColor Green
    Write-Host "   Token: $($newToken.Substring(0, 30))..." -ForegroundColor Gray
    
    # Mostrar información del token
    $tokenParts = $newToken.Split('.')
    if ($tokenParts.Count -ge 2) {
        $payloadBase64 = $tokenParts[1]
        while ($payloadBase64.Length % 4) { $payloadBase64 += "=" }
        $payloadBytes = [System.Convert]::FromBase64String($payloadBase64)
        $payloadJson = [System.Text.Encoding]::UTF8.GetString($payloadBytes)
        $tokenData = $payloadJson | ConvertFrom-Json
        
        Write-Host "👤 User Info:" -ForegroundColor Cyan
        Write-Host "   Email: $($tokenData.email)" -ForegroundColor Gray
        Write-Host "   User ID: $($tokenData.user_id)" -ForegroundColor Gray
        Write-Host "   Username: $($tokenData.username)" -ForegroundColor Gray
        if ($tokenData.role) {
            Write-Host "   Role: $($tokenData.role)" -ForegroundColor Gray
        }
        if ($tokenData.exp) {
            $expiry = [datetime]::new(1970,1,1,0,0,0,0,[System.DateTimeKind]::Utc).AddSeconds($tokenData.exp)
            Write-Host "   Expires: $($expiry.ToLocalTime())" -ForegroundColor Gray
        }
    }
    
    return $newToken
} catch {
    Write-Host "❌ Failed to parse login response: $_" -ForegroundColor Red
    Write-Host "   Raw response: $($result.Content)" -ForegroundColor Gray
    exit 1
}
