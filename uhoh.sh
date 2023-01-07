#!/usr/bin/env bash
set -euo pipefail

json_escape () {
    printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()),end="")'
}

json_message=$(json_escape "$*")
json_push='{"type":"note","title":"uh oh","body":'"${json_message}"'}'
token_location="$(dirname $0)/.pushbullet-token"
token=$(cat $token_location)

curl https://api.pushbullet.com/v2/pushes -X POST \
  -H "Content-Type: application/json" \
  -H "Access-Token: ${token}" \
  --data-raw "$json_push"
