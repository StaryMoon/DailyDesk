# Contributing to DailyDesk

Thanks for taking a look at DailyDesk. The project is intentionally small: a native macOS desktop widget for daily tasks, local rewards, and a tiny desktop pet.

## Good First Contributions

- Improve README examples, screenshots, and release notes.
- Add small AppKit polish without changing the desktop-window behavior.
- Improve Settings wording and validation.
- Add import/export for `config.json`.
- Add tests or scripts that use `DAILYDESK_HOME` so local user data is not touched.

## Important AppKit Constraints

Please preserve these pieces unless you have tested a replacement:

- `DeskWindow` can become key/main even though it is borderless.
- `DeskWindow.sendEvent` wakes the parked desktop-level window before handling mouse/key events.
- `FocusTextField.acceptsFirstMouse` keeps the bottom input clickable.
- `focusInput()` is needed for first-click text entry in the glass widget.
- Unpinned windows should park at `CGWindowLevel.desktopIconWindow`, not disappear.
- Reward state is local-only and should not become background tracking.

## Local Build

```bash
./Scripts/build-release.sh
open Build/DailyDesk.app
```

For CLI tests, isolate state:

```bash
DAILYDESK_HOME="$(mktemp -d)" Build/DailyDesk.app/Contents/MacOS/DailyDesk --generate
```

## Pull Request Checklist

- Build passes with `./Scripts/build-release.sh`.
- New behavior does not touch real user state during tests.
- README or docs are updated when user-facing behavior changes.
- No background monitoring, analytics, or cloud sync is added.

