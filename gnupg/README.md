# GPG Keys Directory

This directory stores GPG/PGP keys for commit signing and encryption.

## Important Security Notes

⚠️ **ALL KEY FILES IN THIS DIRECTORY ARE GITIGNORED**

- Never commit private keys to version control
- The `.gitignore` file ensures no `.key`, `.asc`, or `.gpg` files are tracked
- Only `gpg-agent.conf` configuration is tracked

## Files in this directory

- `gpg-agent.conf` - GPG agent configuration (tracked)
- `signing-key.asc` - Your private GPG key for signing (gitignored)
- `public-key.asc` - Your public GPG key (gitignored)
- Other GPG runtime files - All gitignored

## Usage

Use the setup script to manage your GPG keys:

```bash
./scripts/setup-gpg-key.sh
```

This script provides options to:
1. Generate new GPG keys
2. Import existing keys
3. Export keys to this directory
4. Configure Git to use GPG signing
5. Test GPG signing

## Backup Recommendations

Since these keys are gitignored, make sure to:
1. Keep secure backups of your private keys
2. Store them in a password manager or encrypted storage
3. Never share your private keys

## Restoring Keys

When setting up on a new machine:
1. Run `./scripts/setup-gpg-key.sh`
2. Choose option 2 or 3 to import your existing key
3. The script will configure Git automatically