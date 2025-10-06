# bulk_create_emails.sh

Bulk mailbox creation utility for CyberPanel via cloudAPI.

## Overview

`bulk_create_emails.sh` is a Bash script designed to automate the creation of email accounts on a CyberPanel server using its cloudAPI. You provide a file containing email addresses, and the script:

- Extracts the local-part (username) from each email.
- Determines the domain automatically (unless you specify one).
- Invokes the CyberPanel cloudAPI to create mailboxes for each user.
- Uses a default password ("Secret123+") or a custom one you provide.
- Supports self-signed certificates (with `--insecure` for `curl`).

This script is public-ready and does **not** hardcode any domain or host values.

## Features

- **Bulk creation**: Reads a list of emails and processes them in batch.
- **Domain auto-detection**: If domain is not given, extracts it from the first valid email.
- **Flexible password**: Set a custom password or use the default.
- **API authentication**: Passes the required token in the Authorization header.
- **Safety**: Will not run without all required arguments; strict error handling.
- **Self-signed support**: Uses `curl --insecure` by default for self-signed certs (can be removed).

## Usage

```sh
./bulk_create_emails.sh <TOKEN> <API_URL> <EMAILS_FILE> [PASSWORD] [DOMAIN]
```
- **TOKEN**: The API token (only the body, e.g. `YWR...`). The script sends it as `Authorization: Basic <TOKEN>`.
- **API_URL**: Full CyberPanel cloudAPI URL (e.g. `https://your-panel.example:8090/cloudAPI/`).
- **EMAILS_FILE**: Path to a file with one email address per line.
- **PASSWORD**: _(Optional)_ Password for all accounts; defaults to `Secret123+`.
- **DOMAIN**: _(Optional)_ Domain to use; if omitted, extracted from the first valid email.

### Example

```sh
./bulk_create_emails.sh YWR... "https://your-panel.example:8090/cloudAPI/" emails.txt "Secret123+"
```

## Input File Format

- One email per line:  
  ```
  user1@domain.com
  user2@domain.com
  ```
- Lines beginning with `#` are ignored (comments).
- Empty lines are skipped.

## Output

- For each valid email, the script prints status and calls the API.
- Invalid emails are skipped with a warning.

## Security

- The script uses `--insecure` for `curl` by default to support self-signed certificates. Remove it if not needed.
- The password is visible in logs; use with care.

## Author

- **Jesus Suarez**
- Created: 2025-10-06

## License

MIT (or specify your preferred license)

## Notes

- The script does **not** hardcode any domains or host values.
- API errors and invalid emails are reported to the console.

---
