# Script de prueba simple en PowerShell
$token = Get-Content token.txt -Raw
$token = $token.Trim()

Write-Host "Token: $($token.Substring(0, [Math]::Min(50, $token.Length)))..." -ForegroundColor Cyan

# Headers
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Datos de prueba
$appointmentData = @{
    doctor_id = 1
    appointment_date = (Get-Date).ToString("yyyy-MM-dd")
    appointment_time = "15:00:00"
    reason = "Prueba desde PowerShell"
    status = "scheduled"
} | ConvertTo-Json

Write-Host "`nEnviando datos:" -ForegroundColor Yellow
Write-Host $appointmentData -ForegroundColor Gray

# Intentar crear cita
try {
    $response = Invoke-RestMethod `
        -Uri "http://localhost:8002/api/appointments/" `
        -Method POST `
        -Headers $headers `
        -Body $appointmentData `
        -ContentType "application/json" `
        -TimeoutSec 10
    
    Write-Host "`n✅ ÉXITO: Cita creada!" -ForegroundColor Green
    Write-Host "Respuesta:" -ForegroundColor White
    $response | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor Gray
    
} catch {
    Write-Host "`n❌ ERROR:" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Red
    }
}
