#!/bin/bash
# Sends the clean compose file (no build:, with registry images) to the
# Zoneploy API to start the stack deployment.
set -euo pipefail

CLEAN_COMPOSE="/tmp/zp-compose-clean.yml"

if [ ! -f "$CLEAN_COMPOSE" ]; then
  echo "::error::Processed compose file not found. Make sure the 'Build & push stack images' step ran successfully."
  exit 1
fi

RESPONSE=$(curl -sf -X POST "${ZP_API_URL}/api/v1/deploy" \
  -H "Authorization: Bearer ${ZP_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg composeFile "$(base64 -w 0 "$CLEAN_COMPOSE")" \
    '{composeFile: $composeFile}')")

echo "Deploy started: $(echo "$RESPONSE" | jq -r '.deployUrl // .message // "ok"')"
