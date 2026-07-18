#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration - make versions configurable.
# NODE_VERSIONS and JAVA_VERSIONS hold space-separated lists, but lib/common.sh
# sets IFS to $'\n\t', so plain word splitting will not break them apart. The
# loops below iterate them via split_words().
NODE_VERSIONS="${NODE_VERSIONS:-22 20}"
NODE_DEFAULT="${NODE_DEFAULT:-22}"
JAVA_VERSIONS="${JAVA_VERSIONS:-17 21}"
JAVA_DEFAULT="${JAVA_DEFAULT:-21}"
PHP_VERSION="${PHP_VERSION:-8.4}"
GO_VERSION="${GO_VERSION:-1.25}"
RUBY_VERSION="${RUBY_VERSION:-3.3}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3}"
POSTGRES_VERSION="${POSTGRES_VERSION:-17}"

log_info "Setting up development environments..."

# Export the build environment PHP needs. See the call site for why the
# plugin's own option builder cannot be relied on.
php_build_env() {
    command_exists brew || { log_warn "Homebrew missing; PHP build may fail"; return 0; }

    local bp p d
    bp="$(brew --prefix)"

    # These libraries are keg-only: Homebrew deliberately keeps them off the
    # default search paths, so configure cannot find them without help.
    for p in openssl@3 icu4c zlib libxml2 libedit krb5 gd libzip libpng \
             jpeg-turbo webp freetype gettext libiconv oniguruma readline \
             libsodium gmp bzip2; do
        d="$(brew --prefix "$p" 2>/dev/null)" || continue
        [ -d "$d/lib/pkgconfig" ] && PKG_CONFIG_PATH="${d}/lib/pkgconfig:${PKG_CONFIG_PATH}"
        [ -d "$d/lib" ] && LDFLAGS="-L${d}/lib ${LDFLAGS}"
        [ -d "$d/include" ] && CPPFLAGS="-I${d}/include ${CPPFLAGS}"
    done

    export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}${bp}/lib/pkgconfig"
    export LDFLAGS CPPFLAGS
    export PATH="$(brew --prefix bison)/bin:$(brew --prefix icu4c)/bin:$PATH"

    # PEAR bootstraps by downloading over https using the php binary being
    # built, which fails during a fresh build. Composer replaces it.
    export PHP_WITHOUT_PEAR=yes

    # Libraries found by header probing rather than pkg-config must be named
    # with an explicit prefix, because Homebrew keeps them keg-only. Anything
    # relying on a .pc file (zip, sodium, gmp, jpeg, webp, freetype) resolves
    # through PKG_CONFIG_PATH above and needs no path here.
    export PHP_CONFIGURE_OPTIONS="\
--enable-fpm --enable-mbstring --enable-bcmath --enable-intl --enable-soap \
--enable-sockets --enable-pcntl --enable-exif --enable-gd \
--with-curl --with-zip --with-mysqli --with-pdo-mysql --with-sodium \
--with-gmp --with-jpeg --with-webp --with-freetype --with-mhash \
--with-openssl=$(brew --prefix openssl@3) \
--with-readline=$(brew --prefix readline) \
--with-zlib=$(brew --prefix zlib) \
--with-bz2=$(brew --prefix bzip2) \
--with-gettext=$(brew --prefix gettext) \
--with-iconv=$(brew --prefix libiconv)"
}

# Install latest Xcode using xcodes if available
install_xcode() {
    if command_exists xcodes; then
        log_info "Installing latest Xcode..."
        log_info "Checking for latest Xcode version..."
        xcodes list || log_warn "Failed to list Xcode versions"

        log_info "Installing latest Xcode (this may take a while)..."
        xcodes install --latest --select --experimental-unxip || {
            log_warn "Failed to install Xcode automatically"
            return 1
        }

        ensure_directory "$HOME/.oh-my-zsh/completions"
        xcodes --generate-completion-script > "$HOME/.oh-my-zsh/completions/_xcodes" || {
            log_warn "Failed to generate xcodes completion"
        }
    else
        log_warn "xcodes CLI not available. Skipping Xcode installation."
    fi
}

# Setup asdf plugins and install versions
setup_asdf() {
    if ! command_exists asdf; then
        log_error "asdf is not available. Please install asdf first."
        log_info "You can install asdf from: https://asdf-vm.com/guide/getting-started.html"
        exit 1
    fi

    log_info "Setting up development environments with asdf..."

    # Define plugins to add
    local plugins=(
        "nodejs"
        "bun"
        "java"
        "php"
        "golang"
        "ruby"
        "flutter"
        "postgres"
        "pnpm"
    )

    # Add all plugins
    for plugin in "${plugins[@]}"; do
        log_info "Adding $plugin plugin..."
        asdf plugin add "$plugin" 2>/dev/null || log_info "$plugin plugin already exists"
    done

    # Install Node.js versions
    for version in $(split_words "$NODE_VERSIONS"); do
        log_info "Installing Node.js $version..."
        retry_command asdf install nodejs "latest:$version" || log_warn "Failed to install Node.js $version"
    done

    # Set Node.js default
    log_info "Setting Node.js $NODE_DEFAULT as global default..."
    asdf set --home nodejs "latest:$NODE_DEFAULT" || log_warn "Failed to set Node.js default"

    # Install pnpm latest version
    log_info "Installing pnpm latest version..."
    asdf install pnpm latest || log_warn "Failed to install pnpm"
    asdf set --home pnpm latest || log_warn "Failed to set pnpm default"

    # Install Bun latest version
    log_info "Installing Bun latest version..."
    asdf install bun latest || log_warn "Failed to install Bun"
    asdf set --home bun latest || log_warn "Failed to set Bun default"

    # Install Java versions
    for version in $(split_words "$JAVA_VERSIONS"); do
        log_info "Installing Java $version..."
        asdf install java "latest:openjdk-$version" || log_warn "Failed to install Java $version"
    done

    # Set Java default
    log_info "Setting Java $JAVA_DEFAULT as global default..."
    asdf set --home java "latest:openjdk-$JAVA_DEFAULT" || log_warn "Failed to set Java default"

    # Install PHP (asdf-php automatically installs Composer)
    #
    # The asdf-php plugin builds its own configure options, but that logic is
    # stale for PHP 8.x on current Homebrew:
    #   - it probes for openssl@1.1, which is end-of-life and no longer exists,
    #     so --with-openssl is silently omitted. The resulting binary has no
    #     https wrapper, and `make install-pear` then fails because PEAR
    #     bootstraps by downloading over https with that very binary.
    #   - it emits --with-<lib>-dir flags that PHP 8 removed.
    #   - bzip2 is keg-only on macOS and needs an explicit path.
    # Setting PHP_CONFIGURE_OPTIONS replaces that builder entirely.
    log_info "Installing PHP $PHP_VERSION (includes Composer)..."
    php_build_env
    asdf install php "latest:$PHP_VERSION" || log_warn "Failed to install PHP"
    asdf set --home php "latest:$PHP_VERSION" || log_warn "Failed to set PHP default"

    # Install Go
    log_info "Installing Go $GO_VERSION..."
    asdf install golang "latest:$GO_VERSION" || log_warn "Failed to install Go"
    asdf set --home golang "latest:$GO_VERSION" || log_warn "Failed to set Go default"

    # Install Ruby
    log_info "Installing Ruby $RUBY_VERSION..."
    asdf install ruby "latest:$RUBY_VERSION" || log_warn "Failed to install Ruby"
    asdf set --home ruby "latest:$RUBY_VERSION" || log_warn "Failed to set Ruby default"

    # Install Flutter
    log_info "Installing Flutter $FLUTTER_VERSION..."
    asdf install flutter "latest:$FLUTTER_VERSION" || log_warn "Failed to install Flutter"
    asdf set --home flutter "latest:$FLUTTER_VERSION" || log_warn "Failed to set Flutter default"

    # Install PostgreSQL
    log_info "Installing PostgreSQL $POSTGRES_VERSION..."
    asdf install postgres "latest:$POSTGRES_VERSION" || log_warn "Failed to install PostgreSQL"
    asdf set --home postgres "latest:$POSTGRES_VERSION" || log_warn "Failed to set PostgreSQL default"

    # Refresh asdf shims
    log_info "Refreshing asdf shims..."
    asdf reshim || log_warn "Failed to refresh shims"

    log_info "asdf setup complete!"
    log_info "Installed versions:"
    for plugin in "${plugins[@]}"; do
        asdf list "$plugin" 2>/dev/null || true
    done
}

# Global npm packages. Installed here (not in the Brewfile) because they depend
# on Node.js, which asdf provisions in setup_asdf above. Running them via
# `brew bundle` on a fresh machine would fail because npm does not yet exist.
NPM_GLOBALS=(
    "@dokploy/cli"
    "@fission-ai/openspec@latest"
    "@marp-team/marp-cli"
    "agent-browser"
)

install_npm_globals() {
    if ! command_exists npm; then
        log_warn "npm not found; skipping global npm packages."
        return
    fi

    log_info "Installing global npm packages..."
    for pkg in "${NPM_GLOBALS[@]}"; do
        npm install -g "$pkg" || log_warn "Failed to install npm package: $pkg"
    done
    asdf reshim nodejs 2>/dev/null || true
}

# Install language servers system-wide, one per language in .tool-versions.
#
# These are installed outside Neovim on purpose. Neovim gets its own copies
# through Mason (see nvim/lua/plugins/mason.lua), but Mason's installs live
# under ~/.local/share/nvim and are not visible to anything else. Zed, Cursor,
# serena and command-line tooling need servers on PATH.
#
# Everything installed here lands in a directory already on PATH:
#   - Go servers    -> $LSP_BIN (see below)
#   - npm globals   -> the active node's global prefix, reshimmed by asdf
#   - gems          -> the active ruby's bin, reshimmed by asdf
#   - brew formulae -> $(brew --prefix)/bin
#
# Not installed here, because the SDKs already provide them:
#   - Dart:  `dart language-server`, part of the Dart/Flutter SDK
#   - Swift: sourcekit-lsp, part of the Xcode toolchain
install_language_servers() {
    log_info "Installing language servers..."

    # Go binaries go to ~/.local/bin rather than the asdf default.
    #
    # asdf's golang plugin points GOBIN at the active version's directory
    # (.asdf/installs/golang/<version>/bin), so anything installed there
    # disappears on the next Go upgrade. ~/.local/bin is already on PATH
    # (see zsh/.zshrc_sourced/.path) and survives version changes.
    local LSP_BIN="$HOME/.local/bin"
    ensure_directory "$LSP_BIN"

    if command_exists go; then
        # GOROOT/GOPATH from a shell that predates a Go upgrade make the
        # compiler and driver disagree ("version does not match go tool
        # version"). Clearing them lets go derive its own paths.
        log_info "Installing gopls (Go)..."
        env -u GOROOT -u GOPATH GOBIN="$LSP_BIN" \
            go install golang.org/x/tools/gopls@latest ||
            log_warn "Failed to install gopls"
    else
        log_warn "go not found; skipping gopls"
    fi

    # npm-based servers.
    #
    # typescript-language-server needs the typescript package alongside it; it
    # wraps tsserver rather than reimplementing it.
    if command_exists npm; then
        local pkg
        for pkg in typescript typescript-language-server pyright \
                   intelephense bash-language-server yaml-language-server \
                   vscode-langservers-extracted \
                   dockerfile-language-server-nodejs; do
            log_info "Installing ${pkg}..."
            npm install -g "$pkg" || log_warn "Failed to install $pkg"
        done
        asdf reshim nodejs 2>/dev/null || true
    else
        log_warn "npm not found; skipping npm language servers"
    fi

    # Ruby
    if command_exists gem; then
        log_info "Installing ruby-lsp (Ruby)..."
        gem install ruby-lsp || log_warn "Failed to install ruby-lsp"
        asdf reshim ruby 2>/dev/null || true
    else
        log_warn "gem not found; skipping ruby-lsp"
    fi

    # Servers that are not npm or gem packages. jdtls is the Eclipse JDT
    # language server used for Java; marksman covers Markdown; taplo covers TOML.
    if command_exists brew; then
        local formula
        for formula in jdtls lua-language-server marksman taplo; do
            log_info "Installing ${formula}..."
            brew list --formula "$formula" >/dev/null 2>&1 ||
                brew install "$formula" ||
                log_warn "Failed to install $formula"
        done
    else
        log_warn "brew not found; skipping Java, Lua, Markdown and TOML servers"
    fi

    # Report what is actually resolvable, including the SDK-provided servers.
    log_info "Language server status:"
    local name cmd entry
    for entry in \
        "go:gopls" \
        "typescript/javascript:typescript-language-server" \
        "python:pyright" \
        "php:intelephense" \
        "ruby:ruby-lsp" \
        "java:jdtls" \
        "lua:lua-language-server" \
        "bash:bash-language-server" \
        "yaml:yaml-language-server" \
        "json/html/css:vscode-json-language-server" \
        "dockerfile:docker-langserver" \
        "markdown:marksman" \
        "toml:taplo" \
        "dart:dart" \
        "swift:sourcekit-lsp"; do
        name="${entry%%:*}"
        cmd="${entry##*:}"
        if command_exists "$cmd"; then
            log_info "  ${name}: $(command -v "$cmd")"
        else
            log_warn "  ${name}: not found ($cmd)"
        fi
    done
}

# Main execution
main() {
    install_xcode
    setup_asdf
    install_npm_globals
    install_language_servers

    log_info "Development environment setup complete!"
    log_info "Note: You may need to restart your terminal or source your shell profile to use the installed tools."
}

# Run main function
main "$@"