@echo off
echo Stopping Ollama Portable servers...

taskkill /f /fi "WINDOWTITLE eq OllamaServer" >nul 2>&1
taskkill /f /fi "WINDOWTITLE eq CaddyServer"  >nul 2>&1
taskkill /f /im ollama.exe                    >nul 2>&1
taskkill /f /im caddy.exe                     >nul 2>&1

:: Ensure no leftover listeners on port
for /f %%a in ('powershell -NoProfile -Command ^
"Get-NetTCPConnection -LocalPort 47474 -State Listen -ErrorAction SilentlyContinue ^| Select-Object -ExpandProperty OwningProcess"') do (
    taskkill /f /pid %%a >nul 2>&1
)

timeout /t 2 /nobreak >nul

echo Port 47474 is now free.