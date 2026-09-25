# Enable the game-builder marketplace + plugin for this user (Windows / PowerShell). Run once per machine:
#   powershell -ExecutionPolicy Bypass -File .\enable-plugin.ps1
# Idempotent. Requires Node.js (also needed by the gb verification tool).
$ErrorActionPreference = 'Stop'
node (Join-Path $PSScriptRoot 'tools\enable-plugin.js')
