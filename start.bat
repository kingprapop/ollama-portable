@echo off
title Ollama Portable
cd /d "%~dp0"

:: ========================================
::   PORTABLE PATH SETUP
:: ========================================
set "BASE=%~dp0"

:: Create folders if they don't exist yet
if not exist "%BASE%servers"                mkdir "%BASE%servers"
if not exist "%BASE%models"                  mkdir "%BASE%models"
if not exist "%BASE%servers\config\local"   mkdir "%BASE%servers\config\local"
if not exist "%BASE%servers\config\roaming" mkdir "%BASE%servers\config\roaming"

:: Redirect Ollama model storage to our models folder on the drive
set "OLLAMA_MODELS=%BASE%models"

:: Redirect any Ollama config/temp writes to drive instead of C:\Users
set "LOCALAPPDATA=%BASE%servers\config\local"
set "APPDATA=%BASE%servers\config\roaming"
set "USERPROFILE=%BASE%servers\config"

:: Allow Ollama Portable to call Ollama API through Caddy
set "OLLAMA_ORIGINS=http://localhost:47474"
set "OLLAMA_HOST=127.0.0.1:11434"

echo.
echo ========================================
echo   Ollama Portable - Starting...
echo ========================================
echo.
echo   Location : %BASE%
echo   Models   : %BASE%models
echo   Web UI   : http://localhost:47474
echo ========================================
echo.

:: ========================================
::   CHECK FILES EXIST
:: ========================================
if not exist "%BASE%servers\caddy.exe" (
    echo [!] caddy.exe not found at %BASE%caddy.exe
    echo     Download from https://github.com/caddyserver/caddy/releases/latest
    echo     Get caddy_x.x.x_windows_amd64.zip
    pause
    exit /b 1
)

if not exist "%BASE%servers\ollama.exe" (
    echo [!] ollama.exe not found at %BASE%programs\ollama.exe
    echo     Download from https://github.com/ollama/ollama/releases/latest
    echo     Get ollama-windows-amd64.zip
    pause
    exit /b 1
)

if not exist "%BASE%webui\build\index.html" (
    echo [!] Ollama Portable build not found at %BASE%build\index.html
    echo     Copy your build folder to %BASE%build\
    pause
    exit /b 1
)

:: ========================================
::   CHECK PORT 47474 (LISTENING ONLY)
:: ========================================
powershell -NoProfile -Command ^
"if (Get-NetTCPConnection -LocalPort 47474 -State Listen -ErrorAction SilentlyContinue) { exit 1 } else { exit 0 }"

if %errorlevel% neq 0 (
    echo [!] Port 47474 is already in use.
    echo     Another app is actively using it.
    echo.
    pause
    exit /b 1
)

:: ========================================
::   START OLLAMA
:: ========================================
echo [1/3] Starting Ollama server...

tasklist | find /i "ollama.exe" >nul
if not errorlevel 1 (
    echo       Ollama already running, skipping...
) else (
    start /min "OllamaServer" "%BASE%servers\ollama.exe" serve
    echo       Ollama started.
)

:: Wait for Ollama API to actually respond
echo       Waiting for Ollama to be ready...
:waitollama
timeout /t 1 /nobreak >nul
curl -s http://localhost:11434 >nul 2>&1
if errorlevel 1 goto waitollama
echo       Ollama is ready.
echo.

:: ========================================
::   START CADDY
:: ========================================
echo [2/3] Starting Caddy web server...

tasklist | find /i "caddy.exe" >nul
if not errorlevel 1 (
    echo       Caddy already running, skipping...
) else (
    start /min "CaddyServer" "%BASE%servers\caddy.exe" run --config "%BASE%servers\Caddyfile" --adapter caddyfile
    echo       Caddy started.
)

timeout /t 2 /nobreak >nul
echo.

:: ========================================
::   OPEN BROWSER
:: ========================================
echo [3/3] Opening Ollama Portable in browser...
start "" http://localhost:47474/autosetup.html
echo.
echo ========================================
echo   Ollama Portable is ready!
echo   URL  : http://localhost:47474
echo.
echo ========================================
echo.
echo   Press any key to STOP all servers
echo   and exit...
echo.
pause >nul

:: ========================================
::   SHUTDOWN
:: ========================================
echo.
echo Shutting down all servers...

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

echo All servers stopped. Goodbye!
exit /b 0

