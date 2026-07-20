# Makefile for the dotfiles repository.
#
# Thin wrappers around the scripts in ./scripts. Run `make` or `make help`
# to see every available target.
#
# Examples:
#   make deploy                       # re-link dotfiles
#   make backup                       # encrypted secrets backup to iCloud
#   make restore FILE=/path/to.gpg    # restore a specific backup

SHELL   := /bin/bash
SCRIPTS := ./scripts

# `make restore` picks the newest backup when FILE is empty.
FILE ?=

.DEFAULT_GOAL := help

# ---------------------------------------------------------------------------
# Meta
# ---------------------------------------------------------------------------
.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "; printf "\nUsage: make \033[36m<target>\033[0m\n\n"} \
		/^# ==/ {next} \
		/^[a-zA-Z0-9_-]+:.*## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2} \
		/^## / {printf "\n\033[1m%s\033[0m\n", substr($$0, 4)}' $(MAKEFILE_LIST)
	@echo

## Setup & deployment
.PHONY: setup deploy dev
setup: ## Full new-Mac setup (requires sudo; run once)
	$(SCRIPTS)/setup-new-mac.sh

deploy: ## Deploy/update dotfiles symlinks
	$(SCRIPTS)/deploy-dotfiles.sh

dev: ## Install/update development environments (asdf)
	$(SCRIPTS)/setup-dev-environments.sh

## Packages & shell
.PHONY: brew brew-dump shell-plugins spaceship skills skills-project codebase-memory mcp
brew: ## Install Homebrew packages from the Brewfile
	$(SCRIPTS)/install-brew-packages.sh

# --describe is deprecated (descriptions are the default now), and --global
# targets ~/.Brewfile, which contradicts --file. Both were removed.
brew-dump: ## Regenerate the repository Brewfile from installed packages
	brew bundle dump --file=$(HOME)/.dotfiles/brew/Brewfile --force

shell-plugins: ## Install ZSH shell plugins
	$(SCRIPTS)/install-shell-plugins.sh

spaceship: ## Install the Spaceship ZSH theme
	$(SCRIPTS)/install-spaceship-zsh-theme.sh

skills: ## Install global agent skills (from this repo's .claude/skills-registry.txt)
	$(SCRIPTS)/sync-agent-skills.sh

codebase-memory: ## Install codebase-memory-mcp with the graph UI enabled
	$(SCRIPTS)/setup-codebase-memory.sh

mcp: ## Register serena as an MCP server with Claude Code
	$(SCRIPTS)/setup-mcp-servers.sh

# Run from inside the target project, not from the dotfiles repo:
#   ~/.dotfiles/scripts/sync-agent-skills.sh --project
skills-project: ## Install project skills from ./.claude/skills-registry.txt in $(CURDIR)
	$(SCRIPTS)/sync-agent-skills.sh --project

## Identity: SSH, GPG, Git
.PHONY: ssh gpg git-config
ssh: ## Generate and configure SSH keys
	$(SCRIPTS)/setup-ssh-keys.sh

gpg: ## Set up and manage the GPG signing key
	$(SCRIPTS)/setup-gpg-key.sh

git-config: ## Configure git user and signing
	$(SCRIPTS)/configure-git-user.sh

## Backup & restore (secrets not tracked in this repo)
.PHONY: backup restore
backup: ## Encrypted backup of secrets to iCloud
	$(SCRIPTS)/pre-reinstall-backup.sh

restore: ## Restore secrets from a backup (FILE=<path>; newest if empty)
	$(SCRIPTS)/post-reinstall-restore.sh $(FILE)

## Services
.PHONY: proxy-start proxy-stop proxy-status
proxy-start: ## Start the cliproxyapi service (serves 127.0.0.1:8317 for claudex)
	brew services start cliproxyapi

proxy-stop: ## Stop the cliproxyapi service
	brew services stop cliproxyapi

proxy-status: ## Show cliproxyapi service state and whether the API answers
	@brew services list | grep -i cliproxyapi || true
	@echo "config: $$(readlink $$(brew --prefix)/etc/cliproxyapi.conf 2>/dev/null || echo '(not symlinked - service may use brew template)')"
	@if [ -z "$$CLAUDEX_AUTH_TOKEN" ]; then \
		echo "api /v1/models: skipped (CLAUDEX_AUTH_TOKEN not set; see ~/.zshrc_local)"; \
	else \
		curl -s -o /dev/null -w "api /v1/models: HTTP %{http_code}\n" --max-time 6 \
			-H "Authorization: Bearer $$CLAUDEX_AUTH_TOKEN" http://127.0.0.1:8317/v1/models || true; \
	fi

## Utilities
.PHONY: db-autostart-off
db-autostart-off: ## Prevent database services from auto-starting
	$(SCRIPTS)/prevent-db-autostart.sh
