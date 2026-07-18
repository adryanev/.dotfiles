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
.PHONY: brew brew-dump shell-plugins spaceship token-optimizer skills
brew: ## Install Homebrew packages from the Brewfile
	$(SCRIPTS)/install-brew-packages.sh

brew-dump: ## Regenerate the global Brewfile from installed packages
	brew bundle dump --file=$(HOME)/.dotfiles/brew/Brewfile --force --describe --global

shell-plugins: ## Install ZSH shell plugins
	$(SCRIPTS)/install-shell-plugins.sh

spaceship: ## Install the Spaceship ZSH theme
	$(SCRIPTS)/install-spaceship-zsh-theme.sh

token-optimizer: ## Set up the LLM token optimizer (rtk)
	$(SCRIPTS)/setup-llm-token-optimizer.sh

skills: ## Sync agent skills
	$(SCRIPTS)/sync-agent-skills.sh

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

## Utilities
.PHONY: db-autostart-off
db-autostart-off: ## Prevent database services from auto-starting
	$(SCRIPTS)/prevent-db-autostart.sh
