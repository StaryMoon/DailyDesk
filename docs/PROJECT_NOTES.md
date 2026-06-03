# Project Notes

## Why Swift Package first

This machine currently has Apple Command Line Tools but not a full Xcode installation available to `xcodebuild`. The repo therefore starts with a Swift Package layout and a direct `swiftc` app bundling script.

This keeps the project buildable now while leaving room for a later Xcode project when App Store signing and archiving are needed.

## Data files

```text
~/Library/Application Support/DailyDesk/state.json
~/Library/Application Support/DailyDesk/config.json
```

Use `DAILYDESK_HOME=/tmp/somewhere` for isolated CLI tests.

## Preserved prototype behaviors

- Accessory app with no Dock icon.
- Borderless glass desktop window.
- First-click focus for text input.
- Explicit edit shortcuts and context menu.
- Pinned floating level.
- Unpinned desktop-icon-level parking after deactivation.
- `--pin` and `--unpin` CLI recovery helpers.

