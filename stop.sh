#!/bin/bash

echo "Stopping Ollama Portable servers..."

# Kill by process name
pkill -x "ollama" 2>/dev/null
pkill -x "caddy"  2>/dev/null

# Kill any remaining listeners on port 47474
PIDS=$(lsof -ti TCP:47474 -sTCP:LISTEN 2>/dev/null)
if [ -n "$PIDS" ]; then
    kill -9 $PIDS 2>/dev/null
fi

sleep 2

echo "Port 47474 is now free."