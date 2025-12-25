#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="$DIR/../Godot_v4.5.1"

if [[ -x "$GODOT_BIN" ]]; then
  exec "$GODOT_BIN" --path "$DIR"
else
  echo "Godot executable not found at $GODOT_BIN"
  exit 1
fi
