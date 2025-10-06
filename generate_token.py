#!/usr/bin/env python3
"""
generate_token.py

Generates a header 'Basic <sha256_hex(user:pass)>' from username and password.
"""

import argparse
import hashlib

def generate_token_sha256(server_user: str, server_pass: str) -> str:
    """Generate a Basic token using SHA256(user:pass)."""
    credentials = f"{server_user}:{server_pass}".encode("utf-8")
    sha = hashlib.sha256(credentials).hexdigest()
    return f"Basic {sha}"

def main():
    parser = argparse.ArgumentParser(
        description="Generate a 'Basic' header token using SHA256(user:pass)."
    )
    parser.add_argument(
        "--user", "-u",
        required=True,
        help="Username for the token (required)"
    )
    parser.add_argument(
        "--passw", "-p",
        required=True,
        help="Password for the token (required)"
    )
    parser.add_argument(
        "--show-only",
        action="store_true",
        help="Print only the token without labels"
    )
    args = parser.parse_args()

    token = generate_token_sha256(args.user, args.passw)

    if args.show_only:
        print(token)
    else:
        print("Generated Authorization Header:")
        print(token)

if __name__ == "__main__":
    main()
