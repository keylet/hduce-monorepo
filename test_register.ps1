$url = "http://localhost:8000/auth/register"
$body = @{
    email = "test@hduce.com"
    password = "password123"
    full_name = "Test User"
    role = "patient"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -ContentType "application/json" -Body $body
    Write-Host "✅ REGISTRO EXITOSO:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "❌ ERROR:" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)"
    Write-Host "Message: $($_.Exception.Message)"
    Write-Host "Response: $($_.ErrorDetails.Message)"
}
