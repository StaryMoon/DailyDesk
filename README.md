# DailyDesk

DailyDesk is a native macOS glass desktop planner with a tiny desktop pet: it sits on your wallpaper, keeps today's tasks visible, and turns completion into a small local reward loop.

![DailyDesk screenshot](Screenshots/dailydesk_desktop.png)

<p align="center">
  <img src="Screenshots/azusa_pet_idle.png" width="520" alt="DailyDesk Azusa desktop pet preview">
</p>

> v0.2.1 adds the Azusa-style pixel pet asset pack while keeping the original AppKit-drawn pet as a fallback. Everything is local: no accounts, no network sync, no activity tracking.

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
- Completion rewards with local-only coins.
- A tiny Azusa-style pixel desktop pet that changes mood as today's progress grows.
- AppKit-drawn pet fallback when bundled pet assets are unavailable.
- Calendar warehouse for recent daily completion records.
- Virtual shop for pet accessories such as ribbons, scarves, stars, and crowns.
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

Pet assets under `Resources/PetAssets/` are copied into the app bundle by the release script.

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

`state.json` stores task completion, coin balance, daily records, and equipped pet accessories. DailyDesk does not upload or sync this data.

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
健身 | light | daily |  | none |
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
- Reward state is saved locally inside `AppState`; completing the same task repeatedly does not mint duplicate coins.
- The calendar warehouse and virtual shop are normal AppKit panel windows, not background monitors.
- The pixel pet is loaded from `Contents/Resources/PetAssets/Azusa`; if those resources are missing, `PetView` automatically falls back to the original vector-drawn pet.

Do not remove these pieces unless you have a replacement tested inside a borderless `NSPanel`/`NSWindow`.

## Roadmap

- v0.1: Engineering cleanup, configurable templates, GitHub release build.
- v0.2: Local reward loop, desktop pet, calendar warehouse, virtual shop, pixel pet assets.
- v0.3: Menu bar item, window recovery, import/export config.
- v0.4: Multiple task sets and richer template editor.
- v0.5: User-consented Login Item helper for daily auto-open.
- v1.0: Signed, notarized, and App Store-ready build.

## App Store Status

DailyDesk is not App Store-ready yet. See [docs/APP_STORE_READINESS.md](docs/APP_STORE_READINESS.md).

## License

MIT License.
