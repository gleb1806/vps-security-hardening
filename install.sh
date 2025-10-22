#!/usr/bin/env bash
# install.sh - installer + optional automatic run
# Usage examples:
#   curl -fsSL https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main/install.sh | sudo bash
#   curl -fsSL https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main/install.sh | sudo bash -s -- --no-run

set -euo pipefail

REPO_RAW_BASE="https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main"
SCRIPT_NAME="security-hardening.sh"
DST="/usr/local/bin/${SCRIPT_NAME}"

# Default: run the installed script after install
AUTO_RUN=true

# parse simple args (only --no-run supported here)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-run) AUTO_RUN=false; shift ;;
    --run) AUTO_RUN=true; shift ;;
    *) shift ;;
  esac
done

# helper to fetch file (curl preferred, fallback to wget)
fetch_to() {
  local url="$1" out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$out"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$out" "$url"
  else
    echo "Error: curl or wget required." >&2
    return 1
  fi
}

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "Downloading ${SCRIPT_NAME} from repository..."
fetch_to "${REPO_RAW_BASE}/${SCRIPT_NAME}" "$TMP"

if ! head -n1 "$TMP" | grep -q '^#!'; then
  echo "Downloaded file doesn't look like a script. Aborting." >&2
  exit 1
fi

echo "Installing to $DST"
mv "$TMP" "$DST"
chmod 0755 "$DST"
echo "Installed $DST"

if [ "$AUTO_RUN" = true ]; then
  echo "Running $DST now..."
  # exec заменит текущий процесс, что полезно при pipe | sudo bash
  exec "$DST"
else
  echo "Installation finished. To run the script manually: sudo $DST"
fi
