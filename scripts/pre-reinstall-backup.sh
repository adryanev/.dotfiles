#!/usr/bin/env bash
#
# pre-reinstall-backup.sh
#
# Creates a single encrypted archive of the secrets and state that are NOT
# tracked in this (public) dotfiles repository, and copies it to iCloud Drive.
#
# Contents of the archive:
#   - Headroom memory      (exported from the global DB to JSON)
#   - SSH keys             (~/.ssh: private/public keys, config, known_hosts)
#   - GPG key              (secret key, public key, ownertrust)
#   - cliproxyapi          (config with remote-management secret, plus auth-dir
#                           OAuth logins; neither is tracked in the repo)
#   - Shell secrets        (~/.zshrc_local: API tokens, etc.)
#
# Encryption:
#   The whole bundle is encrypted with gpg --symmetric (AES-256). Symmetric
#   encryption is used on purpose: the backup includes the GPG key itself, so it
#   must be decryptable WITHOUT that key.
#   If BACKUP_ENCRYPTION_PASSPHRASE is set in env/.env-install, it is used
#   non-interactively (for unattended runs). Otherwise you are prompted for a
#   passphrase at backup time and need the SAME passphrase to restore.
#
# Restore:
#   Use post-reinstall-restore.sh on the new machine, or follow the manual
#   steps printed at the end of this script.
#
# Usage:
#   ./pre-reinstall-backup.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../env/.env-install"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"

# --- Configuration ----------------------------------------------------------
ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
DEST_DIR="$ICLOUD/Backups/mac-secrets"
HEADROOM_DB="$HOME/.headroom/memory.db"
CLIPROXY_CONFIG="$HOME/.config/cliproxyapi/config.yaml"
CLIPROXY_AUTH_DIR="$HOME/.cli-proxy-api"
GPG_KEY="A46A577A26A97682"   # Adryan Eka Vandra (Official PGP Key)
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$DEST_DIR/secrets-backup-$STAMP.tar.gz.gpg"

# --- Preflight --------------------------------------------------------------
if [ ! -d "$ICLOUD" ]; then
  echo "ERROR: iCloud Drive not found at: $ICLOUD" >&2
  exit 1
fi
command -v gpg >/dev/null || { echo "ERROR: gpg not installed" >&2; exit 1; }
mkdir -p "$DEST_DIR"

# Secure staging directory; removed on any exit so plaintext never lingers.
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/secrets-backup.XXXXXX")"
chmod 700 "$STAGE"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

FILES=()  # files to place in the bundle

echo "==> Staging secrets in $STAGE"

# --- 1. Headroom memory -----------------------------------------------------
if command -v headroom >/dev/null && [ -f "$HEADROOM_DB" ]; then
  echo "  - Headroom memory ($HEADROOM_DB)"
  headroom memory export --db-path "$HEADROOM_DB" -o "$STAGE/headroom-memory.json"
  FILES+=("headroom-memory.json")
else
  echo "  - Headroom memory: SKIPPED (headroom or DB not found)"
fi

# --- 2. SSH keys ------------------------------------------------------------
if [ -d "$HOME/.ssh" ]; then
  echo "  - SSH keys (~/.ssh)"
  # -h dereferences the 'config' symlink so its real content is captured.
  tar -czf "$STAGE/ssh.tar.gz" -C "$HOME" -h \
    --exclude='.ssh/agent' \
    --exclude='.ssh/*.backup.*' \
    --exclude='.ssh/*.old' \
    .ssh
  FILES+=("ssh.tar.gz")
else
  echo "  - SSH keys: SKIPPED (~/.ssh not found)"
fi

# --- 3. GPG key -------------------------------------------------------------
if gpg --list-secret-keys "$GPG_KEY" >/dev/null 2>&1; then
  echo "  - GPG key $GPG_KEY (you may be prompted for the key passphrase)"
  gpg --export-secret-keys --armor "$GPG_KEY" > "$STAGE/gpg-secret.asc"
  gpg --export --armor        "$GPG_KEY" > "$STAGE/gpg-public.asc"
  gpg --export-ownertrust                > "$STAGE/gpg-ownertrust.txt"
  FILES+=("gpg-secret.asc" "gpg-public.asc" "gpg-ownertrust.txt")
else
  echo "  - GPG key: SKIPPED (secret key $GPG_KEY not found)"
fi

# --- 4. cliproxyapi config + auth -------------------------------------------
# The config holds remote-management.secret-key and is therefore not tracked in
# the public repo; auth-dir holds the provider OAuth logins.
if [ -f "$CLIPROXY_CONFIG" ]; then
  echo "  - cliproxyapi config ($CLIPROXY_CONFIG)"
  cp "$CLIPROXY_CONFIG" "$STAGE/cliproxyapi-config.yaml"
  FILES+=("cliproxyapi-config.yaml")
else
  echo "  - cliproxyapi config: SKIPPED ($CLIPROXY_CONFIG not found)"
fi

if [ -d "$CLIPROXY_AUTH_DIR" ]; then
  echo "  - cliproxyapi auth ($CLIPROXY_AUTH_DIR)"
  tar -czf "$STAGE/cli-proxy-api.tar.gz" -C "$HOME" -h "$(basename "$CLIPROXY_AUTH_DIR")"
  FILES+=("cli-proxy-api.tar.gz")
else
  echo "  - cliproxyapi auth: SKIPPED ($CLIPROXY_AUTH_DIR not found)"
fi

# --- 5. Shell secrets (~/.zshrc_local) ---------------------------------------
if [ -f "$HOME/.zshrc_local" ]; then
  echo "  - Shell secrets (~/.zshrc_local)"
  cp "$HOME/.zshrc_local" "$STAGE/zshrc_local"
  FILES+=("zshrc_local")
else
  echo "  - Shell secrets: SKIPPED (~/.zshrc_local not found)"
fi

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "ERROR: nothing was staged; aborting." >&2
  exit 1
fi

# --- Bundle + encrypt -------------------------------------------------------
echo "==> Bundling ${#FILES[@]} item(s)"
tar -czf "$STAGE/bundle.tar.gz" -C "$STAGE" "${FILES[@]}"

if [ -n "${BACKUP_ENCRYPTION_PASSPHRASE:-}" ]; then
  echo "==> Encrypting (AES-256) with BACKUP_ENCRYPTION_PASSPHRASE from .env-install"
  gpg --batch --yes --pinentry-mode loopback \
    --passphrase "$BACKUP_ENCRYPTION_PASSPHRASE" \
    --symmetric --cipher-algo AES256 --output "$OUT" "$STAGE/bundle.tar.gz"
else
  echo "==> Encrypting (AES-256). Enter a passphrase you will remember for restore:"
  gpg --symmetric --cipher-algo AES256 --output "$OUT" "$STAGE/bundle.tar.gz"
fi

# --- Report -----------------------------------------------------------------
SIZE="$(du -h "$OUT" | cut -f1)"
echo
echo "Backup complete."
echo "  File: $OUT"
echo "  Size: $SIZE"
echo "  Contents: ${FILES[*]}"
echo
echo "Restore on the new machine with:"
echo "  ./post-reinstall-restore.sh \"$OUT\""
