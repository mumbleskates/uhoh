#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

json_escape () {
    printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()),end="")'
}

TITLE="uh oh : $(hostname)"
MESSAGE="$*"

FOUND=

# For pushover, put a file named `.pushover-keys` containing two KEY=value
# entries for PUSHOVER_USER and PUSHOVER_TOKEN in this folder next to the
# real uhoh.sh file.
if [[ -f ./.pushover-keys ]]; then
  source ./.pushover-keys

  # pushover priorities: https://pushover.net/api#priority
  # default to 'normal' priority
  PRIORITY_NUMBER=0
  # default to "normal" priority
  PRIORITY="${PRIORITY-normal}"
  # lowercase the priority value
  PRIORITY="${PRIORITY,,}"
  case "${PRIORITY}" in
    lowest)
      PRIORITY_NUMBER=-2
      ;;
    low)
      PRIORITY_NUMBER=-1
      ;;
    normal)
      PRIORITY_NUMBER=0
      ;;
    high)
      PRIORITY_NUMBER=1
      ;;
    emergency)
      PRIORITY_NUMBER=2
      ;;
  esac

  curl https://api.pushover.net/1/messages.json \
    --form-string "user=${PUSHOVER_USER}" \
    --form-string "token=${PUSHOVER_TOKEN}" \
    --form-string "message=${MESSAGE}" \
    --form-string "title=${TITLE}" \
    --form-string "priority=${PRIORITY_NUMBER}" \
    --silent
  FOUND=true
fi

# For pushbullet, put a file named `.pushbullet-token` containing the token
# in this folder next to the real uhoh.sh file.
if [[ -f ./.pushbullet-token ]]; then
  JSON_MESSAGE="$(json_escape "${MESSAGE}")"
  JSON_TITLE="$(json_escape "${TITLE}")"
  JSON_PUSH='{"type":"note","title":'"${JSON_TITLE}"',"body":'"${JSON_MESSAGE}"'}'
  TOKEN="$(cat ./.pushbullet-token)"

  curl https://api.pushbullet.com/v2/pushes \
    --silent \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Access-Token: ${TOKEN}" \
    --data-raw "${JSON_PUSH}"
  FOUND=true
fi

if [[ -z "${FOUND}" ]]; then
  echo "uh oh: no backend configured!"
  exit 1
fi
