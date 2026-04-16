#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin:$HOME/Scripts"
export HEADROOM_MODE="${HEADROOM_MODE:-token}"

HEADROOM_BIN="${HEADROOM_BIN:-$HOME/.local/bin/headroom}"
HEADROOM_HOME="${HEADROOM_HOME:-$HOME/.headroom}"
HEADROOM_MEMORY_DB_PATH="${HEADROOM_MEMORY_DB_PATH:-$HEADROOM_HOME/memory.db}"

if [ ! -x "$HEADROOM_BIN" ]; then
    echo "headroom binary not found at $HEADROOM_BIN" >&2
    exit 1
fi

mkdir -p "$HEADROOM_HOME"

exec "$HEADROOM_BIN" proxy \
    --host 127.0.0.1 \
    --port 8787 \
    --memory \
    --memory-db-path "$HEADROOM_MEMORY_DB_PATH"
