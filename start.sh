#!/bin/bash
# ========================================
#   Ollama Portable - Mac OS
# ========================================

# Get the directory where this script lives
BASE="$(cd "$(dirname "$0")" && pwd)/"

# ========================================
#   PORTABLE PATH SETUP
# ========================================

# Create folders if they don't exist yet
mkdir -p "${BASE}servers"
mkdir -p "${BASE}models"
mkdir -p "${BASE}servers/config/local"
mkdir -p "${BASE}servers/config/roaming"

# Redirect Ollama model storage to our models folder
export OLLAMA_MODELS="${BASE}models"

# Redirect Ollama config/temp writes to drive instead of ~/Library
export HOME="${BASE}servers/config"
export XDG_CONFIG_HOME="${BASE}servers/config/local"
export XDG_DATA_HOME="${BASE}servers/config/roaming"

# Allow Ollama Portable to call Ollama API through Caddy
export OLLAMA_ORIGINS="http://localhost:47474"
export OLLAMA_HOST="127.0.0.1:11434"

echo ""
echo "========================================"
echo "  Ollama Portable - Starting..."
echo "========================================"
echo ""
echo "  Location : ${BASE}"
echo "  Models   : ${BASE}models"
echo "  Web UI   : http://localhost:47474"
echo "========================================"
echo ""

# ========================================
#   FIRST RUN: DOWNLOAD OLLAMA BINARY
# ========================================
SENTINEL="${BASE}servers/.downloaded"

if [ ! -f "$SENTINEL" ]; then
    echo "[Setup] Downloading Ollama binary - this only happens once..."
    echo ""

    echo "  Downloading ollama-darwin.tgz (124 MB)..."
    curl -L --progress-bar -o "${BASE}ollama-darwin.tgz" \
        "https://github.com/ollama/ollama/releases/download/v0.20.7/ollama-darwin.tgz"

    if [ $? -ne 0 ]; then
        echo "[!] Failed to download ollama-darwin.tgz"
        read -rp "Press Enter to exit..." _
        exit 1
    fi

    echo ""
    echo "  Extracting ollama-darwin.tgz to servers/..."
    tar -xzf "${BASE}ollama-darwin.tgz" -C "${BASE}servers/"

    if [ $? -ne 0 ]; then
        echo "[!] Failed to extract ollama-darwin.tgz"
        read -rp "Press Enter to exit..." _
        exit 1
    fi

    rm -f "${BASE}ollama-darwin.tgz"
    chmod +x "${BASE}servers/ollama"

    # Mark as done so this block never runs again
    touch "$SENTINEL"

    echo ""
    echo "  Download and setup complete."
    echo ""
fi

# ========================================
#   CHECK FILES EXIST
# ========================================
if [ ! -f "${BASE}webui/build/index.html" ]; then
    echo "[!] Ollama Portable build not found at ${BASE}webui/build/index.html"
    echo "    Copy your build folder to ${BASE}webui/build/"
    read -rp "Press Enter to exit..." _
    exit 1
fi

if [ ! -f "${BASE}servers/caddy" ]; then
    echo "[!] caddy not found at ${BASE}servers/caddy"
    echo "    Download from https://github.com/caddyserver/caddy/releases/latest"
    echo "    Get caddy_x.x.x_mac_amd64.tar.gz"
    read -rp "Press Enter to exit..." _
    exit 1
fi

# ========================================
#   CHECK PORT 47474
# ========================================
if lsof -iTCP:47474 -sTCP:LISTEN -t &>/dev/null; then
    echo "[!] Port 47474 is already in use."
    echo "    Another app is actively using it."
    echo ""
    read -rp "Press Enter to exit..." _
    exit 1
fi

# ========================================
#   START OLLAMA
# ========================================
echo "[1/4] Starting Ollama server..."

if pgrep -x "ollama" > /dev/null; then
    echo "      Ollama already running, skipping..."
else
    "${BASE}servers/ollama" serve &>/dev/null &
    echo "      Ollama started."
fi

# Wait for Ollama API to actually respond
echo "      Waiting for Ollama to be ready..."
until curl -s http://localhost:11434 &>/dev/null; do
    sleep 1
done
echo "      Ollama is ready."
echo ""

# ========================================
#   FIRST RUN: PULL DEFAULT MODEL
# ========================================
MODEL_SENTINEL="${BASE}models/.gemma4-pulled"

if [ ! -f "$MODEL_SENTINEL" ]; then
    echo "[2/4] Downloading default model gemma4:e2b-it-q4_K_M..."
    echo "      This only happens once. Please wait..."
    echo ""
    "${BASE}servers/ollama" pull gemma4:e2b-it-q4_K_M
    if [ $? -ne 0 ]; then
        echo "[!] Failed to download model gemma4:e2b-it-q4_K_M"
        echo "    Check your internet connection and try again."
        read -rp "Press Enter to exit..." _
        exit 1
    fi
    touch "$MODEL_SENTINEL"
    echo ""
    echo "      Model downloaded successfully."
    echo ""
else
    echo "[2/4] Default model already downloaded, skipping..."
    echo ""
fi

# ========================================
#   START CADDY
# ========================================
echo "[3/4] Starting Caddy web server..."

if pgrep -x "caddy" > /dev/null; then
    echo "      Caddy already running, skipping..."
else
    "${BASE}servers/caddy" run \
        --config "${BASE}servers/Caddyfile" \
        --adapter caddyfile &>/dev/null &
    echo "      Caddy started."
fi

sleep 2
echo ""

# ========================================
#   OPEN BROWSER
# ========================================
echo "[4/4] Opening Ollama Portable in browser..."
open "http://localhost:47474/autosetup.html"
echo ""
echo "========================================"
echo "  Ollama Portable is ready!"
echo "  URL  : http://localhost:47474/autosetup.html"
echo ""
echo "========================================"
echo ""
echo "  Press Enter to STOP all servers"
echo "  and exit..."
echo ""
read -rp "" _

# ========================================
#   SHUTDOWN
# ========================================
echo ""
echo "Shutting down all servers..."

pkill -x ollama  2>/dev/null
pkill -x caddy   2>/dev/null

# Ensure no leftover listeners on port 47474
PIDS=$(lsof -iTCP:47474 -sTCP:LISTEN -t 2>/dev/null)
if [ -n "$PIDS" ]; then
    kill -9 $PIDS 2>/dev/null
fi

sleep 2

echo "All servers stopped. Goodbye!"
exit 0