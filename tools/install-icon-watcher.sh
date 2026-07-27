#!/usr/bin/env bash
#
# install-icon-watcher.sh — OPTIONAL. Makes the manifest rebuild itself.
#
# Installs a macOS LaunchAgent that watches IconsHD/ and re-runs
# build-icon-manifest.sh whenever the folder changes. After that you never run
# anything: drop icons in, then /reload in WoW.
#
#   ./tools/install-icon-watcher.sh            install + start
#   ./tools/install-icon-watcher.sh --remove   stop + uninstall
#
# This installs ONE file outside the repo (~/Library/LaunchAgents/…plist) and is
# fully reversible with --remove. It is not required — "Rebuild Icons.command"
# does the same job on demand.

set -euo pipefail
cd "$(dirname "$0")/.."
REPO="$(pwd)"

LABEL="com.gloomsuite.gloomsbars.iconwatch"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

if [ "${1:-}" = "--remove" ]; then
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  rm -f "$PLIST"
  echo "icon watcher removed."
  exit 0
fi

mkdir -p "$HOME/Library/LaunchAgents" "$REPO/IconsHD"

cat > "$PLIST" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$REPO/tools/build-icon-manifest.sh</string>
  </array>
  <key>WatchPaths</key>
  <array>
    <string>$REPO/IconsHD</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>/tmp/$LABEL.log</string>
  <key>StandardErrorPath</key><string>/tmp/$LABEL.log</string>
</dict>
</plist>
PLISTEOF

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "icon watcher installed."
echo "  drop icons into IconsHD/ -> manifest rebuilds itself -> /reload in WoW"
echo "  log:    /tmp/$LABEL.log"
echo "  remove: ./tools/install-icon-watcher.sh --remove"
