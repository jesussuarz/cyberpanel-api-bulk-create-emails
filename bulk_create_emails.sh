#!/usr/bin/env bash
# bulk_create_emails.sh
# Author: Jesus Suarez
# Created: 2025-10-06
#
# Description:
# Reads a text file containing email addresses (one per line), extracts the username
# (the part before '@'), and uses the CyberPanel cloudAPI to create each mailbox.
#
# Notes:
# - Provide only the token string (the part after "Basic "), e.g. YWR...
# - To obtain the token, go to CyberPanel > Databases > phpMyAdmin,
#   open the "cyberpanel" database, then open the table "loginSystem_administrator".
#   Copy the value from the "token" field and replace it in the command below.
#   Video reference: https://youtu.be/HPCTDdEJ_gk?t=196
# - API URL should be the full cloudAPI endpoint, e.g. "https://your-host:8090/cloudAPI/"
# - Default password for created accounts: "Secret123+" (can be changed)
# - Uses --insecure to allow self-signed certificates; remove if not needed.

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <TOKEN> <API_URL> <EMAILS_FILE> [PASSWORD] [DOMAIN]

  TOKEN       : token (only the token body). Script sends the header "Authorization: Basic <TOKEN>"
                To obtain the token, go to CyberPanel > Databases > phpMyAdmin, open the
                "cyberpanel" database, then look for the table "loginSystem_administrator".
                Copy the value in the "token" field and replace it in the command above.
                (Video: https://youtu.be/HPCTDdEJ_gk?t=196)

  API_URL     : full cloudAPI URL (e.g. https://your-panel.example:8090/cloudAPI/)
  EMAILS_FILE : file containing one email address per line
  PASSWORD    : optional password for all accounts (default: Secret123+)
  DOMAIN      : optional domain; if omitted, extracted from first valid email in file

Example:
  ./bulk_create_emails.sh YWR... "https://your-panel.example:8090/cloudAPI/" emails.txt "Secret123+"
EOF
}

if [[ $# -lt 3 ]]; then
  usage
  exit 1
fi

TOKEN="$1"
API_URL="$2"
EMAILS_FILE="$3"
PASSWORD="${4:-Secret123+}"
DOMAIN_ARG="${5:-}"

if [[ ! -f "$EMAILS_FILE" ]]; then
  echo "ERROR: Emails file not found: $EMAILS_FILE" >&2
  exit 2
fi

# Derive domain if not provided
if [[ -z "$DOMAIN_ARG" ]]; then
  first_email=$(grep -Eo "^[[:space:]]*[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}" "$EMAILS_FILE" | head -n1 || true)
  if [[ -z "$first_email" ]]; then
    echo "ERROR: Unable to extract domain from the file. Please specify DOMAIN manually." >&2
    exit 3
  fi
  DOMAIN="$(echo "$first_email" | awk -F'@' '{print $2}' | tr -d '[:space:]')"
else
  DOMAIN="$DOMAIN_ARG"
fi

AUTH_HEADER="Authorization: Basic ${TOKEN}"
CONTENT_HEADER="Content-Type: application/json"

echo "API URL: $API_URL"
echo "Domain: $DOMAIN"
echo "Default password: $PASSWORD"
echo "Emails file: $EMAILS_FILE"
echo

# Process each email address
while IFS= read -r line || [[ -n "$line" ]]; do
  email=$(echo "$line" | tr -d '\r' | sed 's/^[ \t]*//;s/[ \t]*$//')
  if [[ -z "$email" ]] || [[ "$email" =~ ^# ]]; then
    continue
  fi

  # Validate and extract username
  if [[ "$email" =~ ^([A-Za-z0-9._%+-]+)@([A-Za-z0-9.-]+\.[A-Za-z]{2,})$ ]]; then
    user="${BASH_REMATCH[1]}"
    user="$(echo "$user" | tr '[:upper:]' '[:lower:]')"
  else
    echo "SKIP: invalid format -> '$email'"
    continue
  fi

  json_payload=$(printf '{"serverUserName":"admin","controller":"submitEmailCreation","domain":"%s","username":"%s","passwordByPass":"%s"}' \
    "$DOMAIN" "$user" "$PASSWORD")

  echo "-> Creating ${user}@${DOMAIN} ..."
  response=$(curl -sS --insecure --location "$API_URL" \
    -H "$AUTH_HEADER" \
    -H "$CONTENT_HEADER" \
    --data "$json_payload" 2>&1) || rc=$?
  rc=${rc:-0}

  if [[ $rc -ne 0 ]]; then
    echo "  ERROR (curl failed, exit $rc):"
    echo "  $response"
  else
    if command -v jq >/dev/null 2>&1; then
      echo "  Response: $(echo "$response" | jq -c '.')"
    else
      echo "  Response: $response"
    fi
  fi

  sleep 0.2
done < "$EMAILS_FILE"

echo "All tasks completed."
