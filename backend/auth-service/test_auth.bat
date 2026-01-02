@echo off
chcp 65001 > nul
echo ========================================
echo    TEST DEL SERVICIO DE AUTENTICACIÓN
echo ========================================
echo.

REM Verificar si curl está disponible
where curl >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: curl no está instalado o no está en el PATH.
    echo Instala curl o agrégalo al PATH.
    pause
    exit /b 1
)

echo [1/4] Probando health check...
curl -s -X GET "http://localhost:8000/health"
echo.
echo.

echo [2/4] Probando simple-register...
curl -s -X POST "http://localhost:8000/api/auth/simple-register" ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"testuser\",\"email\":\"test@example.com\",\"password\":\"test123\"}"
echo.
echo.

echo [3/4] Probando login (debería fallar primero)...
curl -s -X POST "http://localhost:8000/api/auth/login" ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"testuser\",\"password\":\"test123\"}"
echo.
echo.

echo [4/4] Probando ruta protegida (necesita token)...
echo (Esta prueba requiere un token válido)
echo.
echo.

echo ========================================
echo     PRUEBAS COMPLETADAS
echo ========================================
echo.
echo Para probar manualmente:
echo 1. Asegúrate de que el servidor esté corriendo: python main.py
echo 2. Prueba este comando:
echo    curl -X POST "http://localhost:8000/api/auth/simple-register" ^
echo      -H "Content-Type: application/json" ^
echo      -d "{\"username\":\"test2\",\"email\":\"test2@test.com\",\"password\":\"123\"}"
echo.
pause
