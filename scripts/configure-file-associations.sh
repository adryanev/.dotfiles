#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_info "Configuring file associations and Quick Look extensions..."

# Xcode registers itself as an editor for most text and source UTIs. When no
# explicit default is set, LaunchServices ranks Xcode above the alternatives and
# Finder opens Markdown, JSON and similar files in it. The associations below
# override that ranking. Without them a rebuilt machine silently reverts.
MARKDOWN_EDITOR_BUNDLE_ID="dev.zed.Zed"

# net.daringfireball.markdown is the only Markdown UTI that can be bound here.
# public.markdown appears in the LaunchServices registry as a binding declared
# by individual applications, but macOS does not export it as a type with a
# conformance chain, so duti rejects it with "does not conform to any UTI
# hierarchy". Do not add it back.
MARKDOWN_UTIS=(
    "net.daringfireball.markdown"
)

QUICKLOOK_APP="/Applications/QLMarkdown.app"
QUICKLOOK_EXTENSION="${QUICKLOOK_APP}/Contents/PlugIns/Markdown QL Extension.appex"

# Point a UTI at an application, but only when it is not already correct.
set_default_handler() {
    local uti=$1
    local bundle_id=$2
    local current

    current="$(duti -x "$uti" 2>/dev/null | tail -1)"

    if [ "$current" = "$bundle_id" ]; then
        log_info "$uti already handled by $bundle_id"
        return 0
    fi

    if duti -s "$bundle_id" "$uti" all 2>/dev/null; then
        log_info "Set $uti handler to $bundle_id"
    else
        log_warn "Could not set $uti handler to $bundle_id"
    fi
}

configure_markdown_editor() {
    if ! command_exists duti; then
        log_warn "duti is not installed; skipping file associations"
        log_warn "Install it with: brew bundle --file=brew/Brewfile"
        return 0
    fi

    # duti reports success even for an application that is not installed, which
    # leaves the type bound to nothing and Finder falling back to Xcode.
    #
    # Presence is resolved by bundle identifier rather than by path, because the
    # application may live outside /Applications. `open -Ra` is not usable here:
    # it matches on application name, not identifier.
    if [ -z "$(mdfind "kMDItemCFBundleIdentifier == '$MARKDOWN_EDITOR_BUNDLE_ID'" 2>/dev/null)" ]; then
        log_warn "$MARKDOWN_EDITOR_BUNDLE_ID is not installed; skipping Markdown associations"
        return 0
    fi

    local uti
    for uti in "${MARKDOWN_UTIS[@]}"; do
        set_default_handler "$uti" "$MARKDOWN_EDITOR_BUNDLE_ID"
    done

    # Extensions are deliberately not set here. duti resolves a bare ".md" to its
    # UTI before writing, so `duti -s ... .md` produces the same single
    # net.daringfireball.markdown entry as the loop above rather than a separate
    # extension binding. Verified against com.apple.launchservices.secure.plist,
    # which holds exactly one Markdown entry after this script runs.
}

# QLMarkdown ships its Quick Look support as an app extension inside the app
# bundle. macOS only registers a bundled extension after the containing app has
# been launched at least once, and `brew install --cask` never launches it. The
# extension therefore stays inert after a fresh install and Xcode's Quick Look
# extension previews Markdown instead. `pluginkit -a` announces it directly, so
# no launch is required.
register_quicklook_extension() {
    if [ ! -d "$QUICKLOOK_APP" ]; then
        log_warn "QLMarkdown is not installed; skipping Quick Look registration"
        return 0
    fi

    if [ ! -d "$QUICKLOOK_EXTENSION" ]; then
        log_warn "Quick Look extension not found at $QUICKLOOK_EXTENSION"
        log_warn "The QLMarkdown bundle layout may have changed; register it manually"
        return 0
    fi

    if pluginkit -a "$QUICKLOOK_EXTENSION" 2>/dev/null; then
        log_info "Registered the QLMarkdown Quick Look extension"
    else
        log_warn "Could not register the QLMarkdown Quick Look extension"
        return 0
    fi

    # Registration is not verified afterwards. `pluginkit -a` returns before the
    # registry reflects the change, and `qlmanage -r` below makes Quick Look
    # re-scan its providers, so `pluginkit -m` intermittently reports the
    # extension as absent when a direct query shows it present. A check that
    # warns about a condition that is not true trains the reader to ignore
    # warnings, so the unreliable poll was removed rather than given a longer
    # timeout. Confirm the result by pressing Space on a Markdown file.
    #
    # Quick Look caches the provider it resolved for a type, so a newly
    # registered extension is not used until the cache is reset.
    qlmanage -r >/dev/null 2>&1
    qlmanage -r cache >/dev/null 2>&1
    log_info "Reset the Quick Look cache"

    # Third-party Quick Look extensions require user consent, which no script can
    # grant. This is stated unconditionally because it cannot be detected.
    log_info "If Markdown previews as source text, enable the extension in System Settings"
    log_info "  > General > Login Items & Extensions > Quick Look"
}

main() {
    configure_markdown_editor
    register_quicklook_extension

    log_info "File association configuration complete!"
}

main "$@"
