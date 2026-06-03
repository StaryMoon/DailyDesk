#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/Build/DailyDesk.app"

cd "$ROOT"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

swiftc -O \
  -framework AppKit \
  -framework Foundation \
  -framework CoreGraphics \
  "$ROOT"/Sources/DailyDesk/*.swift \
  -o "$APP/Contents/MacOS/DailyDesk"

echo "$APP"
