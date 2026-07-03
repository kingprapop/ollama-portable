@echo off
title Ollama Portable
cd /d "%~dp0"

:: ========================================
::   PORTABLE PATH SETUP
:: ========================================
set "BASE=%~dp0"

:: Create folders if they don't exist yet
if not exist "%BASE%servers"                mkdir "%BASE%servers"
if not exist "%BASE%models"                 mkdir "%BASE%models"
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
::    FETCH LATEST OLLAMA VERSION
:: ========================================
echo Checking for latest Ollama version...
for /f "delims=" %%I in ('powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $r = Invoke-RestMethod -Uri 'https://api.github.com/repos/ollama/ollama/releases/latest'; $r.tag_name"') do set "OLLAMA_LATEST=%%I"

if "%OLLAMA_LATEST%"=="" (
    echo [!] Failed to fetch Ollama version from GitHub. Skipping check...
    goto CHECK_CADDY
)

set "OLLAMA_SENTINEL=%BASE%servers\.downloaded_ollama_%OLLAMA_LATEST%"

:: Check if Ollama has EVER been downloaded
dir /b "%BASE%servers\.downloaded_ollama_*" >nul 2>&1
if errorlevel 1 (
    echo [Setup] First run: Auto-downloading Ollama %OLLAMA_LATEST%...
    goto DOWNLOAD_OLLAMA
)

:: Check if already up to date
if exist "%OLLAMA_SENTINEL%" (
    echo Ollama is up to date ^(%OLLAMA_LATEST%^).
    goto CHECK_CADDY
)

:: Prompt for Ollama update
echo.
echo --------------------------------------------------------
echo [!] New Ollama update available: %OLLAMA_LATEST%
echo     Press Y to update now
echo     Press N to skip
echo     Default: Y after 5 seconds
echo --------------------------------------------------------
choice /c YN /t 5 /d Y /m "Do you want to update Ollama now?"

if errorlevel 2 (
    echo Skipping Ollama update.
    goto CHECK_CADDY
)

:DOWNLOAD_OLLAMA
echo Downloading Ollama %OLLAMA_LATEST%...
curl -L --progress-bar -o "%BASE%ollama-windows-amd64.zip" "https://github.com/ollama/ollama/releases/download/%OLLAMA_LATEST%/ollama-windows-amd64.zip"
curl -L --progress-bar -o "%BASE%ollama-windows-amd64-rocm.zip" "https://github.com/ollama/ollama/releases/download/%OLLAMA_LATEST%/ollama-windows-amd64-rocm.zip"

powershell -NoProfile -Command "Expand-Archive -Path '%BASE%ollama-windows-amd64.zip' -DestinationPath '%BASE%servers' -Force"
powershell -NoProfile -Command "Expand-Archive -Path '%BASE%ollama-windows-amd64-rocm.zip' -DestinationPath '%BASE%servers' -Force"

del /q "%BASE%ollama-windows-amd64.zip" "%BASE%ollama-windows-amd64-rocm.zip"
del /q "%BASE%servers\.downloaded_ollama_*" 2>nul
echo. > "%OLLAMA_SENTINEL%"
echo Ollama update complete.
echo.

:: ========================================
::    FETCH LATEST CADDY VERSION
:: ========================================
:CHECK_CADDY
echo Checking for latest Caddy version...
for /f "delims=" %%I in ('powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $r = Invoke-RestMethod -Uri 'https://api.github.com/repos/caddyserver/caddy/releases/latest'; $r.tag_name.TrimStart('v') "') do set "CADDY_LATEST=%%I"

if "%CADDY_LATEST%"=="" (
    echo [!] Failed to fetch Caddy version from GitHub. Skipping check...
    goto START_FLOW
)

set "CADDY_SENTINEL=%BASE%servers\.downloaded_caddy_%CADDY_LATEST%"

:: Check if Caddy has EVER been downloaded
dir /b "%BASE%servers\.downloaded_caddy_*" >nul 2>&1
if errorlevel 1 (
    echo [Setup] First run: Auto-downloading Caddy v%CADDY_LATEST%...
    goto DOWNLOAD_CADDY
)

:: Check if already up to date
if exist "%CADDY_SENTINEL%" (
    echo Caddy is up to date ^(v%CADDY_LATEST%^).
    goto START_FLOW
)

:: Prompt for Caddy update
echo.
echo --------------------------------------------------------
echo [!] New Caddy update available: v%CADDY_LATEST%
echo     Press Y to update now
echo     Press N to skip
echo     Default: Y after 5 seconds
echo --------------------------------------------------------
choice /c YN /t 5 /d Y /m "Do you want to update Caddy now?"
if errorlevel 2 (
    echo Skipping Caddy update.
    goto START_FLOW
)

:DOWNLOAD_CADDY
echo Downloading Caddy v%CADDY_LATEST%...
:: FIX: Download as .zip instead of writing over caddy.exe directly
curl -L --progress-bar -o "%BASE%caddy.zip" "https://github.com/caddyserver/caddy/releases/download/v%CADDY_LATEST%/caddy_%CADDY_LATEST%_windows_amd64.zip"

if errorlevel 1 (
    echo [!] Failed to download Caddy.
    pause
    exit /b 1
)

:: FIX: Extract the zip contents to the servers folder
echo Extracting Caddy...
powershell -NoProfile -Command "Expand-Archive -Path '%BASE%caddy.zip' -DestinationPath '%BASE%servers' -Force"

:: FIX: Clean up the temporary zip file
del /q "%BASE%caddy.zip"

del /q "%BASE%servers\.downloaded_caddy_*" 2>nul
echo. > "%CADDY_SENTINEL%"
echo Caddy update complete.


:: ========================================
::   CHECK FILES EXIST
:: ========================================
if not exist "%BASE%webui\build\index.html" (
    echo [!] Ollama Portable build not found at %BASE%webui\build\index.html
    echo     Copy your build folder to %BASE%webui\build\
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
echo [1/4] Starting Ollama server...

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
::   FIRST RUN: PULL DEFAULT MODEL
:: ========================================
set "MODEL_SENTINEL=%BASE%models\.gemma4-pulled"

if not exist "%MODEL_SENTINEL%" (
    echo [2/4] Downloading default model gemma4:e2b-it-q4_K_M...
    echo       This only happens once. Please wait...
    echo.
    "%BASE%servers\ollama.exe" pull gemma4:e2b-it-q4_K_M
    if errorlevel 1 (
        echo [!] Failed to download model gemma4:e2b-it-q4_K_M
        echo     Check your internet connection and try again.
        pause
        exit /b 1
    )
    echo. > "%MODEL_SENTINEL%"
    echo.
    echo       Model downloaded successfully.
    echo.
) else (
    echo [2/4] Default model already downloaded, skipping...
    echo.
)

:: ========================================
::   START CADDY
:: ========================================
echo [3/4] Starting Caddy web server...

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
echo [4/4] Opening Ollama Portable in browser...
start "" http://localhost:47474/autosetup.html
echo.
echo ========================================
echo   Ollama Portable is ready!
echo   URL  : http://localhost:47474/autosetup.html
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
