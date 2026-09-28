#!/bin/bash
# Etch installer.   curl -fsSL https://etchapp.cc/install.sh | bash
set -euo pipefail

HOST="${ETCH_SERVER:-https://etchapp.cc}"
VERSION="${ETCH_VERSION:-1.0.0}"
APPS="$HOME/Applications"
LABEL="com.makbanjac.etch.widget"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

say() { printf '  %s\n' "$*"; }
die() { printf '\n  %s\n\n' "$*" >&2; exit 1; }

printf '\n  Etch\n\n'

MAJOR=$(sw_vers -productVersion | cut -d. -f1)
[ "$MAJOR" -ge 13 ] || die "Etch needs macOS 13 or newer (this Mac has $(sw_vers -productVersion))."

TMP=$(mktemp -d)

say "Downloading..."
curl -fsSL "$HOST/etch-$VERSION.tar.gz" -o "$TMP/etch.tar.gz" \
  || die "Download failed. Check your connection and try again."
tar -xzf "$TMP/etch.tar.gz" -C "$TMP" || die "The download was incomplete. Try again."
[ -d "$TMP/Etch.app" ] || die "That archive did not contain Etch."

say "Installing fonts..."
mkdir -p "$HOME/Library/Fonts"
if [ -d "$TMP/fonts" ]; then
  for f in "$TMP/fonts/"*.ttf; do [ -f "$f" ] && cp -f "$f" "$HOME/Library/Fonts/"; done
fi

say "Installing..."
mkdir -p "$APPS" "$HOME/.Trash"
launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
pkill -f "EtchWidget.app/Contents/MacOS" 2>/dev/null || true
STAMP=$(date +%Y%m%d-%H%M%S)
for app in Etch.app EtchWidget.app; do
  # An older copy goes to the Trash rather than being destroyed, so a bad
  # upgrade is always recoverable.
  [ -d "$APPS/$app" ] && mv "$APPS/$app" "$HOME/.Trash/$app.$STAMP"
  ditto "$TMP/$app" "$APPS/$app"
  # curl does not set the quarantine flag, but a browser download would have.
  xattr -dr com.apple.quarantine "$APPS/$app" 2>/dev/null || true
done

say "Setting it to start at login..."
mkdir -p "$(dirname "$PLIST")"
cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>$APPS/EtchWidget.app/Contents/MacOS/EtchWidget</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ProcessType</key><string>Interactive</string>
  <key>LimitLoadToSessionType</key><string>Aqua</string>
</dict></plist>
PL
launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$PLIST" 2>/dev/null || launchctl load "$PLIST" 2>/dev/null || true

open "$APPS/Etch.app" 2>/dev/null || true
printf '\n  Done. Etch is on your desktop, and in your Dock for settings.\n'
printf '  Remove it any time:  curl -fsSL %s/uninstall.sh | bash\n\n' "$HOST"
