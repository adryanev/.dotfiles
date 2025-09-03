#!/usr/bin/env bash

# Source common utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/../scripts/lib/common.sh" ]; then
    source "${SCRIPT_DIR}/../scripts/lib/common.sh"
else
    # Fallback logging functions
    log_info() { echo "[INFO] $1"; }
    log_warn() { echo "[WARN] $1"; }
    log_error() { echo "[ERROR] $1" >&2; }
fi

# macOS Configuration Script
# Updated for macOS Sonoma/Sequoia (14.x/15.x)
# Run with: ./macos.sh

log_info "Configuring macOS settings..."
log_warn "Some changes require a logout/restart to take effect"

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing sudo time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Close any open System Settings panes
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

###############################################################################
# General UI/UX                                                               #
###############################################################################

log_info "Configuring General UI/UX settings..."

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Remove duplicates in the "Open With" menu
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -kill -r -domain local -domain system -domain user 2>/dev/null || true

# Display ASCII control characters using caret notation
defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true

# Disable Resume system-wide
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

# Disable automatic termination of inactive apps
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

# Set Help Viewer windows to non-floating mode
defaults write com.apple.helpviewer DevMode -bool true

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable automatic text replacement
defaults write NSGlobalDomain NSAutomaticTextReplacementEnabled -bool false

# Enable subpixel font rendering on non-Apple LCDs
defaults write NSGlobalDomain AppleFontSmoothing -int 1

# Enable HiDPI display modes (requires restart)
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true 2>/dev/null || true

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

log_info "Configuring input devices..."

# Trackpad: enable tap to click for this user and login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: enable three finger drag
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

# Enable full keyboard access for all controls
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Use scroll gesture with the Ctrl (^) modifier key to zoom
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144

# Follow the keyboard focus while zoomed in
defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

# Set a fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Set language and text formats
defaults write NSGlobalDomain AppleLanguages -array "en" "id"
defaults write NSGlobalDomain AppleLocale -string "id_ID@currency=IDR"
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults write NSGlobalDomain AppleMetricUnits -bool true

# Show language menu in the top right corner
defaults write com.apple.TextInputMenu visible -bool false

###############################################################################
# Energy saving                                                               #
###############################################################################

log_info "Configuring energy settings..."

# Enable lid wakeup
sudo pmset -a lidwake 1 2>/dev/null || log_warn "Failed to set lidwake"

# Sleep the display after 15 minutes
sudo pmset -a displaysleep 15 2>/dev/null || log_warn "Failed to set displaysleep"

# Set machine sleep to 30 minutes while charging
sudo pmset -c sleep 30 2>/dev/null || log_warn "Failed to set sleep (charging)"

# Set machine sleep to 15 minutes on battery
sudo pmset -b sleep 15 2>/dev/null || log_warn "Failed to set sleep (battery)"

# Set standby delay to 24 hours (default is 1 hour)
sudo pmset -a standbydelay 86400 2>/dev/null || log_warn "Failed to set standbydelay"

# Never go into computer sleep mode
# sudo pmset -a sleep 0

# Hibernation mode
# 0: Disable hibernation (speeds up entering sleep mode)
# 3: Copy RAM to disk so the system state can still be restored in case of power failure
sudo pmset -a hibernatemode 0 2>/dev/null || log_warn "Failed to set hibernatemode"

# Remove the sleep image file to save disk space
sudo rm -f /private/var/vm/sleepimage 2>/dev/null || true
# Create a zero-byte file instead
sudo touch /private/var/vm/sleepimage 2>/dev/null || true
# Make sure it can't be rewritten
sudo chflags uchg /private/var/vm/sleepimage 2>/dev/null || true

###############################################################################
# Screen                                                                      #
###############################################################################

log_info "Configuring screen settings..."

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Create screenshots directory if it doesn't exist
mkdir -p "${HOME}/Pictures/Screenshots"

# Save screenshots to custom directory
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"

# Save screenshots in PNG format (options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Include date in screenshot filenames
defaults write com.apple.screencapture include-date -bool true

# Show thumbnail after taking a screenshot
defaults write com.apple.screencapture show-thumbnail -bool true

###############################################################################
# Finder                                                                      #
###############################################################################

log_info "Configuring Finder..."

# Allow quitting via ⌘ + Q; doing so will also hide desktop icons
defaults write com.apple.finder QuitMenuItem -bool true

# Show icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Enable spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# Remove the spring loading delay for directories
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Disable disk image verification
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Use list view in all Finder windows by default
# Four-letter codes for view modes: `icnv`, `clmv`, `glyv`, `Nlsv`
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Enable AirDrop over Ethernet and on unsupported Macs
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# Show the ~/Library folder
chflags nohidden ~/Library 2>/dev/null || log_warn "Failed to unhide ~/Library"

# Show the /Volumes folder
sudo chflags nohidden /Volumes 2>/dev/null || log_warn "Failed to unhide /Volumes"

# Expand the following File Info panes
defaults write com.apple.finder FXInfoPanesExpanded -dict \
    General -bool true \
    OpenWith -bool true \
    Privileges -bool true

###############################################################################
# Dock, Dashboard, and hot corners                                            #
###############################################################################

log_info "Configuring Dock and Dashboard..."

# Enable highlight hover effect for the grid view of a stack (Dock)
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Set the icon size of Dock items to 48 pixels
defaults write com.apple.dock tilesize -int 48

# Change minimize/maximize window effect
defaults write com.apple.dock mineffect -string "scale"

# Minimize windows into their application's icon
defaults write com.apple.dock minimize-to-application -bool true

# Enable spring loading for all Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool true

# Don't animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool false

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# Don't group windows by application in Mission Control
defaults write com.apple.dock expose-group-by-app -bool false

# Disable Dashboard
defaults write com.apple.dashboard mcx-disabled -bool true

# Don't show Dashboard as a Space
defaults write com.apple.dock dashboard-in-overlay -bool true

# Don't automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0

# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -float 0

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Hot corners
# Possible values:
#  0: no-op
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center
# 13: Lock Screen

# Top left screen corner → Mission Control
defaults write com.apple.dock wvous-tl-corner -int 2
defaults write com.apple.dock wvous-tl-modifier -int 0

# Top right screen corner → Desktop
defaults write com.apple.dock wvous-tr-corner -int 4
defaults write com.apple.dock wvous-tr-modifier -int 0

# Bottom left screen corner → Lock Screen
defaults write com.apple.dock wvous-bl-corner -int 13
defaults write com.apple.dock wvous-bl-modifier -int 0

# Bottom right screen corner → Launchpad
defaults write com.apple.dock wvous-br-corner -int 11
defaults write com.apple.dock wvous-br-modifier -int 0

###############################################################################
# Safari & WebKit                                                             #
###############################################################################

log_info "Configuring Safari..."

# Privacy: don't send search queries to Apple
defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true

# Show the full URL in the address bar
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Set Safari's home page
defaults write com.apple.Safari HomePage -string "about:blank"

# Prevent Safari from opening 'safe' files automatically
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# Allow hitting the Backspace key to go to the previous page
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true

# Hide Safari's bookmarks bar by default
defaults write com.apple.Safari ShowFavoritesBar -bool false

# Hide Safari's sidebar in Top Sites
defaults write com.apple.Safari ShowSidebarInTopSites -bool false

# Enable Safari's debug menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

# Enable the Develop menu and the Web Inspector
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Add a context menu item for showing the Web Inspector
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# Enable continuous spellchecking
defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true

# Disable auto-correct
defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false

# Warn about fraudulent websites
defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

# Enable "Do Not Track"
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true

###############################################################################
# Mail                                                                        #
###############################################################################

log_info "Configuring Mail..."

# Disable send and reply animations
defaults write com.apple.mail DisableReplyAnimations -bool true
defaults write com.apple.mail DisableSendAnimations -bool true

# Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>`
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# Display emails in threaded mode
defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "yes"
defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"

# Disable inline attachments
defaults write com.apple.mail DisableInlineAttachmentViewing -bool true

###############################################################################
# Terminal & Ghostty                                                          #
###############################################################################

log_info "Configuring Terminal..."

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# Enable Secure Keyboard Entry in Terminal.app
defaults write com.apple.terminal SecureKeyboardEntry -bool true

# Disable the annoying line marks
defaults write com.apple.Terminal ShowLineMarks -int 0

# Set Ghostty as default terminal if installed
if [ -d "/Applications/Ghostty.app" ]; then
    log_info "Setting Ghostty as default terminal..."
    # This would need additional configuration based on Ghostty's requirements
fi

###############################################################################
# Activity Monitor                                                            #
###############################################################################

log_info "Configuring Activity Monitor..."

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# TextEdit and Disk Utility                                                   #
###############################################################################

log_info "Configuring TextEdit and Disk Utility..."

# Use plain text mode for new TextEdit documents
defaults write com.apple.TextEdit RichText -int 0

# Open and save files as UTF-8 in TextEdit
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# Enable the debug menu in Disk Utility
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true

###############################################################################
# Mac App Store                                                               #
###############################################################################

log_info "Configuring Mac App Store..."

# Enable the WebKit Developer Tools in the Mac App Store
defaults write com.apple.appstore WebKitDeveloperExtras -bool true

# Enable Debug Menu in the Mac App Store
defaults write com.apple.appstore ShowDebugMenu -bool true

# Check for software updates daily
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install System data files & security updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

# Turn on app auto-update
defaults write com.apple.commerce AutoUpdate -bool true

###############################################################################
# Photos                                                                      #
###############################################################################

log_info "Configuring Photos..."

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Messages                                                                    #
###############################################################################

log_info "Configuring Messages..."

# Disable automatic emoji substitution
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false

# Disable continuous spell checking
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false

###############################################################################
# Set Dock Apps                                                               #
###############################################################################

configure_dock() {
    log_info "Configuring Dock applications..."

    # Clear the Dock of all apps
    defaults write com.apple.dock persistent-apps -array

    # Add desired apps to the Dock
    local APPS=(
        "/System/Applications/Finder.app"
        "/System/Applications/Launchpad.app"
        "/Applications/Zen.app"
        "/Applications/Ghostty.app"
        "/System/Applications/Messages.app"
        "/Applications/WhatsApp.app"
        "/Applications/Telegram.app"
        "/Applications/Signal.app"
        "/Applications/Discord.app"
        "/Applications/Visual Studio Code.app"
        "/Applications/Android Studio.app"
        "/Applications/Xcode.app"
        "/Applications/Simulator.app"
        "/Applications/Figma.app"
        "/Applications/Postman.app"
        "/Applications/Notion.app"
        "/System/Applications/Notes.app"
        "/System/Applications/System Settings.app"
        "/System/Applications/Utilities/Activity Monitor.app"
    )

    for app in "${APPS[@]}"; do
        if [ -e "$app" ]; then
            defaults write com.apple.dock persistent-apps -array-add "<dict>
                <key>tile-data</key>
                <dict>
                    <key>file-data</key>
                    <dict>
                        <key>_CFURLString</key>
                        <string>$app</string>
                        <key>_CFURLStringType</key>
                        <integer>0</integer>
                    </dict>
                </dict>
            </dict>"
        else
            log_warn "App not found: $app"
        fi
    done
}

# Configure Dock if requested
read -p "Do you want to reset your Dock with predefined apps? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    configure_dock
fi

###############################################################################
# Kill affected applications                                                  #
###############################################################################

log_info "Restarting affected applications..."

for app in "Activity Monitor" \
    "cfprefsd" \
    "Dock" \
    "Finder" \
    "Mail" \
    "Messages" \
    "Photos" \
    "Safari" \
    "SystemUIServer" \
    "Terminal"; do
    killall "${app}" &> /dev/null || true
done

log_info "macOS configuration complete!"
log_warn "Note that some changes require a logout/restart to take effect."
log_info "You may need to restart your computer for all changes to apply."