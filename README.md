# DailyDesk

DailyDesk is a lightweight macOS desktop day planner: a transparent glass widget that sits on your desktop and shows the few tasks that matter today.

![DailyDesk screenshot](Screenshots/dailydesk_desktop.png)

## Features

- Native Swift + AppKit implementation.
- Transparent borderless desktop window with HUD glass material.
- Dark glass task cards with thin priority accents.
- Three priority levels: urgent, important, light.
- Daily generated task templates.
- Weekly and before-weekly repeat rules.
- Manual task input for today's ad-hoc work.
- Auto-growing window height as the task list grows.
- Transparent scrolling task area when the list exceeds available screen height.
- Click-to-complete progress ring.
- Configurable quick-open targets for local files and links.
- Preferences window for task templates, repeat rules, daily appearance time, pin behavior, and quick links.
- Pin mode:
  - pinned: floats above other windows.
  - unpinned: remains visible like a desktop note, then parks at the desktop icon window level after app deactivation.
- No background time tracking, no activity monitoring, no network sync.

## Build

This repository uses a Swift Package layout plus a small macOS `.app` packaging script. It can be built with Apple Command Line Tools; a full Xcode project can be added later for App Store distribution.

```bash
cd DailyDesk
./Scripts/build-release.sh
open Build/DailyDesk.app
```

The script creates:

```text
Build/DailyDesk.app
```

## CLI

DailyDesk keeps the prototype recovery helpers:

```bash
DailyDesk --generate
DailyDesk --generate --force
DailyDesk --pin
DailyDesk --unpin
DailyDesk --show-config
```

For tests, set `DAILYDESK_HOME` to isolate state and config:

```bash
DAILYDESK_HOME="$(mktemp -d)" Build/DailyDesk.app/Contents/MacOS/DailyDesk --generate
```

## Configuration

User data is stored locally:

```text
~/Library/Application Support/DailyDesk/state.json
~/Library/Application Support/DailyDesk/config.json
```

The Preferences window edits:

- daily appearance time
- default pinned behavior
- AI briefing file path
- Bilibili / GitHub quick links
- task templates
- repeat rules
- open actions

Task template format:

```text
title | priority | recurrence | weekdays | open action | optional target
```

Examples:

```text
科研 3h | urgent | daily |  | none |
AI 技术日报 | important | daily |  | ai-briefing |
家教 | urgent | weekly | 1,6,7 | none |
家教备课 | important | prep-before-weekly | 1,6,7 | none |
```

Supported values:

- `priority`: `urgent`, `important`, `light`
- `recurrence`: `daily`, `weekly`, `prep-before-weekly`
- `weekdays`: `1=Mon ... 7=Sun`
- `open action`: `none`, `ai-briefing`, `bilibili-math`, `bilibili-english`, `github`, `custom-url`, `file-path`

## Important Implementation Notes

The floating window intentionally keeps a few AppKit details from the original prototype:

- `DeskWindow` can become key/main even though it is borderless and accessory-style.
- `DeskWindow.sendEvent` wakes the parked desktop-level window before handling mouse/key events.
- `FocusTextField.acceptsFirstMouse` lets the bottom add input receive the first click.
- The add bar calls `focusInput()` so users can click the broader glass area, not only the text field.
- Standard editing shortcuts and the Edit context menu are explicitly wired for the input field.
- Unpin never calls `orderOut`; it parks the visible widget at `CGWindowLevel.desktopIconWindow` after deactivation.
- `adjustWindowHeight(forTaskCount:)` keeps task rows at a stable height and grows the window before falling back to a transparent scroll view.

Do not remove these pieces unless you have a replacement tested inside a borderless `NSPanel`/`NSWindow`.

## Roadmap

- v0.1: Engineering cleanup, configurable templates, GitHub release build.
- v0.2: Menu bar item, window recovery, import/export config.
- v0.3: Multiple task sets and richer template editor.
- v0.4: User-consented Login Item helper for daily auto-open.
- v1.0: Signed, notarized, and App Store-ready build.

## App Store Status

DailyDesk is not App Store-ready yet. See [docs/APP_STORE_READINESS.md](docs/APP_STORE_READINESS.md).

## License

MIT License.
