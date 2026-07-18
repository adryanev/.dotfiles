#!/usr/bin/env bash
#
# post-reinstall-restore.sh
#
# Restores the encrypted backup produced by pre-reinstall-backup.sh:
#   - SSH keys      -> ~/.ssh (with correct permissions)
#   - GPG key       -> imported into the keyring (secret, public, ownertrust)
#   - cliproxyapi   -> ~/.config/cliproxyapi/config.yaml (chmod 600) and the
#                      ~/.cli-proxy-api auth-dir (provider OAuth logins)
#   - Shell secrets -> ~/.zshrc_local (chmod 600)
#
# Usage:
#   ./post-reinstall-restore.sh [path-to-backup.tar.gz.gpg]
#
# If no path is given, the most recent backup in iCloud is used.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../env/.env-install"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"

# --- Configuration ----------------------------------------------------------
ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
DEST_DIR="$ICLOUD/Backups/mac-secrets"
CLIPROXY_CONFIG="$HOME/.config/cliproxyapi/config.yaml"
CLIPROXY_AUTH_DIR="$HOME/.cli-proxy-api"

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
if [ -n "${BACKUP_ENCRYPTION_PASSPHRASE:-}" ]; then
  echo "==> Decrypting with BACKUP_ENCRYPTION_PASSPHRASE from .env-install"
  gpg --batch --yes --pinentry-mode loopback \
    --passphrase "$BACKUP_ENCRYPTION_PASSPHRASE" \
    --decrypt --output "$STAGE/bundle.tar.gz" "$BACKUP"
else
  echo "==> Decrypting (enter the backup passphrase):"
  gpg --decrypt --output "$STAGE/bundle.tar.gz" "$BACKUP"
fi
tar -xzf "$STAGE/bundle.tar.gz" -C "$STAGE"

# --- 1. SSH keys -------------------------------------------------------------
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

# --- 2. GPG key --------------------------------------------------------------
if [ -f "$STAGE/gpg-secret.asc" ]; then
  echo "==> Importing GPG key (you may be prompted for the key passphrase)"
  [ -f "$STAGE/gpg-public.asc" ] && gpg --import "$STAGE/gpg-public.asc"
  gpg --import "$STAGE/gpg-secret.asc"
  [ -f "$STAGE/gpg-ownertrust.txt" ] && gpg --import-ownertrust "$STAGE/gpg-ownertrust.txt"
  echo "  GPG key imported."
else
  echo "==> GPG: nothing in backup."
fi

# --- 3. cliproxyapi config + auth --------------------------------------------
if [ -f "$STAGE/cliproxyapi-config.yaml" ]; then
  echo "==> Restoring cliproxyapi config to $CLIPROXY_CONFIG"
  mkdir -p "$(dirname "$CLIPROXY_CONFIG")"
  cp "$STAGE/cliproxyapi-config.yaml" "$CLIPROXY_CONFIG"
  chmod 600 "$CLIPROXY_CONFIG"
  echo "  cliproxyapi config restored."
else
  echo "==> cliproxyapi config: nothing in backup."
fi

if [ -f "$STAGE/cli-proxy-api.tar.gz" ]; then
  echo "==> Restoring cliproxyapi auth to $CLIPROXY_AUTH_DIR"
  tar -xzf "$STAGE/cli-proxy-api.tar.gz" -C "$HOME"
  echo "  cliproxyapi auth restored."
else
  echo "==> cliproxyapi auth: nothing in backup."
fi

# --- 4. Shell secrets (~/.zshrc_local) ---------------------------------------
if [ -f "$STAGE/zshrc_local" ]; then
  echo "==> Restoring shell secrets to ~/.zshrc_local"
  cp "$STAGE/zshrc_local" "$HOME/.zshrc_local"
  chmod 600 "$HOME/.zshrc_local"
  echo "  Shell secrets restored."
else
  echo "==> Shell secrets: nothing in backup."
fi

echo
echo "Restore complete."
