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

`state.json` also stores reward state: daily completion records, coin balance, total earned coins, owned pet accessories, and the currently equipped pet accessory. This state is local-only.

## Preserved prototype behaviors

- Accessory app with no Dock icon.
- Borderless glass desktop window.
- First-click focus for text input.
- Explicit edit shortcuts and context menu.
- Pinned floating level.
- Unpinned desktop-icon-level parking after deactivation.
- `--pin` and `--unpin` CLI recovery helpers.

## v0.2 reward loop

- Completing a task grants local coins once per task ID.
- Coin rewards scale with priority and include a full-day completion bonus.
- The main widget shows a small desktop pet and current coin balance.
- Calendar warehouse and virtual shop are AppKit panels opened manually by the user.
