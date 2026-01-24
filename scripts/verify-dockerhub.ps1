Write-Host " Verificando imágenes en Docker Hub..." -ForegroundColor Green

$repos = @(
    "keylet30/hduce-auth",
    "keylet30/hduce-user", 
    "keylet30/hduce-appointment",
    "keylet30/hduce-notification"
)

foreach ($repo in $repos) {
    Write-Host "`n $repo" -ForegroundColor Yellow
    try {
        $url = "https://hub.docker.com/v2/repositories/$repo/tags/"
        $response = Invoke-RestMethod -Uri $url -Method Get -ErrorAction Stop
        Write-Host "    Disponible ($($response.count) tags)" -ForegroundColor Green
        if ($response.results) {
            $response.results | ForEach-Object { 
                Write-Host "     - $($_.name) (updated: $($_.last_updated.Substring(0,10)))" 
            }
        }
    } catch {
        Write-Host "    No encontrado en Docker Hub" -ForegroundColor Red
    }
}
