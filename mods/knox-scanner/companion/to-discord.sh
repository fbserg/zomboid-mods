#!/usr/bin/env bash
# Posts each new Knox Scanner line to a Discord webhook. Leave it running while you play.
# Usage: to-discord.sh https://discord.com/api/webhooks/...
set -euo pipefail
webhook="$1"
feed="$HOME/Zomboid/Lua/KnoxScanner.txt"
touch "$feed"
tail -n 0 -F "$feed" | while IFS= read -r line; do
  curl --silent --show-error --fail -H 'Content-Type: application/json' --data "$line" "$webhook"
done
