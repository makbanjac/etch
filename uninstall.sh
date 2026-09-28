#!/bin/bash
set -euo pipefail
LABEL="com.makbanjac.etch.widget"
APPS="$HOME/Applications"
STAMP=$(date +%Y%m%d-%H%M%S)
launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
pkill -f "EtchWidget.app/Contents/MacOS" 2>/dev/null || true
[ -f "$HOME/Library/LaunchAgents/$LABEL.plist" ] && mv "$HOME/Library/LaunchAgents/$LABEL.plist" "$HOME/.Trash/$LABEL.plist.$STAMP"
for app in Etch.app EtchWidget.app; do
  [ -d "$APPS/$app" ] && mv "$APPS/$app" "$HOME/.Trash/$app.$STAMP"
done
printf '\n  Etch has been moved to the Trash.\n'
printf '  Your settings and licence stay in ~/Library/Application Support/Etch\n'
printf '  so reinstalling picks up where you left off.\n\n'
