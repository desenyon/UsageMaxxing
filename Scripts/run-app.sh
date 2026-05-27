#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$("$ROOT/Scripts/build-app.sh")"
open -n "$APP_PATH"
echo "Launched $APP_PATH"
