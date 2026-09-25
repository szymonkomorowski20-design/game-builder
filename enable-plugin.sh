#!/usr/bin/env bash
# Enable the game-builder marketplace + plugin for this user (macOS / Linux). Run once per machine:
#   ./enable-plugin.sh
# Idempotent. Requires Node.js (also needed by the gb verification tool).
set -euo pipefail
node "$(dirname "$0")/tools/enable-plugin.js"
