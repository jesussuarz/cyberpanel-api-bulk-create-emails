#!/usr/bin/env bash
# generate_token_sha256.sh
# Generate a header 'Basic <sha256_hex(user:pass)>' from username and password.

set -e

# Function to show usage
usage() {
    echo "Usage: $0 --user <username> --pass <password> [--show-only]"
    echo
    echo "Example:"
    echo "  $0 --user admin --pass 'MyPassword123'"
    echo "  $0 -u admin -p 'MyPassword123' --show-only"
    exit 1
}

# Parse arguments
USER=""
PASS=""
SHOW_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --user|-u)
            USER="$2"
            shift 2
            ;;
        --pass|-p)
            PASS="$2"
            shift 2
            ;;
        --show-only)
            SHOW_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate inputs
if [[ -z "$USER" || -z "$PASS" ]]; then
    echo "Error: both --user and --pass are required."
    usage
fi

# Generate SHA256 hash
CREDENTIALS="${USER}:${PASS}"
HASH=$(printf "%s" "$CREDENTIALS" | sha256sum | awk '{print $1}')
TOKEN="Basic ${HASH}"

# Output result
if $SHOW_ONLY; then
    echo "$TOKEN"
else
    echo "Generated Authorization Header:"
    echo "$TOKEN"
fi
