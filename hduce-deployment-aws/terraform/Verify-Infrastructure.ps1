# ============================================
# VERIFICACIÓN RÁPIDA - INFRAESTRUCTURA AWS
# ============================================
Write-Host " Estado de Terraform:" -ForegroundColor Cyan
terraform show | Select-String -Pattern "(aws_instance|public_ip|private_ip)" -Context 1

Write-Host "`n IPs Disponibles:" -ForegroundColor Cyan
if (Test-Path "terraform_outputs.json") {
    $outputs = Get-Content "terraform_outputs.json" | ConvertFrom-Json
    if ($outputs.bastion_public_ip) {
        Write-Host "SSH Bastion: ssh -i ..\keys\hduce-qa-key.pem ec2-user@$($outputs.bastion_public_ip.value)" -ForegroundColor Green
    }
    if ($outputs.frontend_public_ip) {
        Write-Host "Frontend Web: http://$($outputs.frontend_public_ip.value)" -ForegroundColor Green
    }
}

Write-Host "`n Archivos de claves:" -ForegroundColor Cyan
Get-ChildItem "..\keys\" -ErrorAction SilentlyContinue | Format-Table Name, Length, LastWriteTime
