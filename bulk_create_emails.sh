#!/usr/bin/env bash
# bulk_create_emails.sh
# Author: Jesus Suarez
# Created: 2025-10-06
#
# Reads a file with email addresses (one per line), extracts the local-part
# (left of '@') and calls a CyberPanel cloudAPI endpoint to create mailboxes.
#
# Notes:
# - Pass only the token body (the part that goes after "Basic "), e.g. YWR...
# - API URL must be the full cloudAPI URL, e.g. "https://example.com:8090/cloudAPI/"
# - Script does not hardcode any domain or host values (public-ready).
# - Default password for created accounts is "Secret123+" unless overridden.
# - Use --insecure by default to tolerate self-signed certs; remove if unnecessary.

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <TOKEN> <API_URL> <EMAILS_FILE> [PASSWORD] [DOMAIN]

  TOKEN       : token (only the token body). Script will send header "Authorization: Basic <TOKEN>"
  API_URL     : full cloudAPI URL (e.g. https://your-panel.example:8090/cloudAPI/)
  EMAILS_FILE : file with emails, one per line (example: user1@domain.com)
  PASSWORD    : (optional) password to set for all accounts. Default: Secret123+
  DOMAIN      : (optional) domain to use. If omitted, the script will extract domain
                from the first valid email line in the file.

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
  echo "ERROR: emails file not found: $EMAILS_FILE" >&2
  exit 2
fi

# Derive domain if not provided
if [[ -z "$DOMAIN_ARG" ]]; then
  first_email=$(grep -Eo "^[[:space:]]*[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}" "$EMAILS_FILE" | head -n1 || true)
  if [[ -z "$first_email" ]]; then
    echo "ERROR: Could not extract a domain from the emails file. Provide DOMAIN as 5th arg." >&2
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
echo "Password used for accounts: $PASSWORD"
echo "Emails file: $EMAILS_FILE"
echo

# Process each line (skip empty or commented lines)
while IFS= read -r line || [[ -n "$line" ]]; do
  email=$(echo "$line" | tr -d '\r' | sed 's/^[ \t]*//;s/[ \t]*$//')
  if [[ -z "$email" ]] || [[ "$email" =~ ^# ]]; then
    continue
  fi

  # Validate and extract local-part
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
  # Use --insecure to allow self-signed certs. Remove if not needed.
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

  # small pause to avoid overloading the API
  sleep 0.2

done < "$EMAILS_FILE"

echo "All done."
