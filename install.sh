#!/usr/bin/env bash
# install.sh - remote installer: fetches main script from GitHub raw and installs to /usr/local/bin
# Usage:
# curl -sSL https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main/install.sh | sudo bash
# or run locally after paste: sudo bash install.sh

set -euo pipefail

REPO_RAW_BASE="https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main"
SCRIPT_NAME="security-hardening.sh"
DST="/usr/local/bin/${SCRIPT_NAME}"

# Check for curl or wget
if command -v curl >/dev/null 2>&1; then
  fetch() { curl -fsSL "$1" -o "$2"; }
elif command -v wget >/dev/null 2>&1; then
  fetch() { wget -qO "$2" "$1"; }
else
  echo "Error: curl or wget required."
  exit 1
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "Downloading ${SCRIPT_NAME} from repository..."
fetch "${REPO_RAW_BASE}/${SCRIPT_NAME}" "$TMP"

if ! head -n1 "$TMP" | grep -q '^#!'; then
  echo "Downloaded file doesn't look like a script. Aborting."
  exit 1
fi

echo "Installing to $DST"
mv "$TMP" "$DST"
chmod 0755 "$DST"

echo "Installed $DST"
echo "Run: sudo $DST"
