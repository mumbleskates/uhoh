#!/usr/bin/env bash
set -euo pipefail

cd $(dirname $(readlink -f "$0"))

json_escape () {
    printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()),end="")'
}

message="$(hostname): $*"

# For pushover, put a file named `.pushover-keys` containing two KEY=value
# entries for PUSHOVER_USER and PUSHOVER_TOKEN in this folder next to the
# real uhoh.sh file.
if [[ -f ./.pushover-keys ]]; then
  source ./.pushover-keys
  curl https://api.pushover.net/1/messages.json \
    --form-string "user=${PUSHOVER_USER}" \
    --form-string "token=${PUSHOVER_TOKEN}" \
    --form-string "message=${message}" \
    --form-string "title=uh oh" \
    --silent
fi

# For pushbullet, put a file named `.pushbullet-token` containing the token
# in this folder next to the real uhoh.sh file.
if [[ -f ./.pushbullet-token ]]; then
  json_message=$(json_escape "${message}")
  json_push='{"type":"note","title":"uh oh","body":'"${json_message}"'}'
  token=$(cat ./.pushbullet-token)

  curl https://api.pushbullet.com/v2/pushes \
    --silent \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Access-Token: ${token}" \
    --data-raw "${json_push}"
fi

echo "no backend tokens found!"
