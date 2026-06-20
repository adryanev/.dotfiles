#!/usr/bin/env bash
#
# post-reinstall-restore.sh
#
# Restores the encrypted backup produced by pre-reinstall-backup.sh:
#   - SSH keys      -> ~/.ssh (with correct permissions)
#   - GPG key       -> imported into the keyring (secret, public, ownertrust)
#   - Headroom memory -> imported into the global DB
#
# Usage:
#   ./post-reinstall-restore.sh [path-to-backup.tar.gz.gpg]
#
# If no path is given, the most recent backup in iCloud is used.
#
set -euo pipefail

# --- Configuration ----------------------------------------------------------
ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
DEST_DIR="$ICLOUD/Backups/mac-secrets"
HEADROOM_DB="$HOME/.headroom/memory.db"

# --- Locate the backup file -------------------------------------------------
if [ "${1:-}" != "" ]; then
  BACKUP="$1"
else
  BACKUP="$(ls -t "$DEST_DIR"/secrets-backup-*.tar.gz.gpg 2>/dev/null | head -1 || true)"
fi
if [ -z "${BACKUP:-}" ] || [ ! -f "$BACKUP" ]; then
  echo "ERROR: backup file not found. Pass the path explicitly." >&2
  exit 1
fi
command -v gpg >/dev/null || { echo "ERROR: gpg not installed" >&2; exit 1; }
echo "==> Restoring from: $BACKUP"

# Secure staging directory; removed on any exit.
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/secrets-restore.XXXXXX")"
chmod 700 "$STAGE"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

# --- Decrypt + unpack -------------------------------------------------------
echo "==> Decrypting (enter the backup passphrase):"
gpg --decrypt --output "$STAGE/bundle.tar.gz" "$BACKUP"
tar -xzf "$STAGE/bundle.tar.gz" -C "$STAGE"

# --- 1. SSH keys ------------------------------------------------------------
if [ -f "$STAGE/ssh.tar.gz" ]; then
  echo "==> Restoring SSH keys to ~/.ssh"
  tar -xzf "$STAGE/ssh.tar.gz" -C "$HOME"
  chmod 700 "$HOME/.ssh"
  # Private keys -> 600, public keys -> 644.
  find "$HOME/.ssh" -maxdepth 1 -type f ! -name '*.pub' -exec chmod 600 {} \;
  find "$HOME/.ssh" -maxdepth 1 -type f -name '*.pub' -exec chmod 644 {} \;
  echo "  SSH keys restored."
else
  echo "==> SSH: nothing in backup."
fi

# --- 2. GPG key -------------------------------------------------------------
if [ -f "$STAGE/gpg-secret.asc" ]; then
  echo "==> Importing GPG key (you may be prompted for the key passphrase)"
  [ -f "$STAGE/gpg-public.asc" ] && gpg --import "$STAGE/gpg-public.asc"
  gpg --import "$STAGE/gpg-secret.asc"
  [ -f "$STAGE/gpg-ownertrust.txt" ] && gpg --import-ownertrust "$STAGE/gpg-ownertrust.txt"
  echo "  GPG key imported."
else
  echo "==> GPG: nothing in backup."
fi

# --- 3. Headroom memory -----------------------------------------------------
if [ -f "$STAGE/headroom-memory.json" ]; then
  if command -v headroom >/dev/null; then
    echo "==> Importing Headroom memory into $HEADROOM_DB"
    mkdir -p "$(dirname "$HEADROOM_DB")"
    headroom memory import "$STAGE/headroom-memory.json" --db-path "$HEADROOM_DB" --force
    echo "  Memory imported."
  else
    cp "$STAGE/headroom-memory.json" "$HOME/headroom-memory-restore.json"
    echo "==> headroom not installed; saved JSON to ~/headroom-memory-restore.json"
    echo "    Import later with: headroom memory import ~/headroom-memory-restore.json --db-path \"$HEADROOM_DB\" --force"
  fi
else
  echo "==> Headroom memory: nothing in backup."
fi

echo
echo "Restore complete."
