#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$SCRIPT_DIR/"

# ========================================
#   PORTABLE PATH SETUP
# ========================================
mkdir -p "$BASE/servers"
mkdir -p "$BASE/models"
mkdir -p "$BASE/servers/config/local"
mkdir -p "$BASE/servers/config/roaming"

export OLLAMA_MODELS="$BASE/models"
export LOCALAPPDATA="$BASE/servers/config/local"
export APPDATA="$BASE/servers/config/roaming"
export USERPROFILE="$BASE/servers/config"
export OLLAMA_ORIGINS="http://localhost:47474"
export OLLAMA_HOST="127.0.0.1:11434"

echo ""
echo "========================================"
echo "  Ollama Portable - Starting..."
echo "========================================"
echo ""
echo "  Location : $BASE"
echo "  Models   : ${BASE}models"
echo "  Web UI   : http://localhost:47474"
echo "========================================"
echo ""

# ========================================
#   CHECK FILES EXIST
# ========================================
if [ ! -f "$BASE/servers/caddy" ]; then
    echo "[!] caddy not found at ${BASE}servers/caddy"
    echo "    Download from https://github.com/caddyserver/caddy/releases/latest"
    echo "    Get caddy_x.x.x_mac_amd64.tar.gz (or arm64 for Apple Silicon)"
    read -p "Press Enter to exit..." 
    exit 1
fi

if [ ! -f "$BASE/servers/ollama" ]; then
    echo "[!] ollama not found at ${BASE}servers/ollama"
    echo "    Download from https://github.com/ollama/ollama/releases/latest"
    echo "    Get the macOS binary"
    read -p "Press Enter to exit..."
    exit 1
fi

if [ ! -f "$BASE/webui/build/index.html" ]; then
    echo "[!] Ollama Portable build not found at ${BASE}webui/build/index.html"
    echo "    Copy your build folder to ${BASE}webui/build/"
    read -p "Press Enter to exit..."
    exit 1
fi

# ========================================
#   CHECK PORT 47474
# ========================================
if lsof -iTCP:47474 -sTCP:LISTEN -t &>/dev/null; then
    echo "[!] Port 47474 is already in use."
    echo "    Another app is actively using it."
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

# ========================================
#   CLEANUP FUNCTION
# ========================================
cleanup() {
    echo ""
    echo "Shutting down all servers..."

    [ -n "$OLLAMA_PID" ] && kill "$OLLAMA_PID" 2>/dev/null
    [ -n "$CADDY_PID" ]  && kill "$CADDY_PID"  2>/dev/null

    # Kill any remaining listeners on 47474
    PIDS=$(lsof -ti TCP:47474 -sTCP:LISTEN 2>/dev/null)
    [ -n "$PIDS" ] && kill -9 $PIDS 2>/dev/null

    sleep 2
    echo "All servers stopped. Goodbye!"
    exit 0
}

trap cleanup SIGINT SIGTERM

# ========================================
#   START OLLAMA
# ========================================
echo "[1/3] Starting Ollama server..."

if pgrep -x "ollama" > /dev/null; then
    echo "      Ollama already running, skipping..."
else
    "$BASE/servers/ollama" serve &>/dev/null &
    OLLAMA_PID=$!
    echo "      Ollama started (PID: $OLLAMA_PID)"
fi

echo "      Waiting for Ollama to be ready..."
until curl -s http://localhost:11434 &>/dev/null; do
    sleep 1
done
echo "      Ollama is ready."
echo ""

# ========================================
#   START CADDY
# ========================================
echo "[2/3] Starting Caddy web server..."

chmod +x "$BASE/servers/caddy"

if pgrep -x "caddy" > /dev/null; then
    echo "      Caddy already running, skipping..."
else
    "$BASE/servers/caddy" run --config "$BASE/servers/Caddyfile" --adapter caddyfile &>/dev/null &
    CADDY_PID=$!
    echo "      Caddy started (PID: $CADDY_PID)"
fi

sleep 2
echo ""

# ========================================
#   OPEN BROWSER
# ========================================
echo "[3/3] Opening Ollama Portable in browser..."
open "http://localhost:47474/autosetup.html"
echo ""
echo "========================================"
echo "  Ollama Portable is ready!"
echo "  URL  : http://localhost:47474/autosetup.html"
echo ""
echo "========================================"
echo ""
echo "  Press Ctrl+C to STOP all servers"
echo "  and exit..."
echo ""

# Keep script alive until Ctrl+C
wait