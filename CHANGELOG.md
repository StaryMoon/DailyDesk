# Changelog

## 0.2.0 - 2026-06-04

- Added a local reward loop: completing tasks grants coins, with higher rewards for urgent tasks and full-day completion.
- Added a small AppKit-drawn desktop pet in the main glass widget.
- Added pet leveling based on total earned coins.
- Added a calendar warehouse panel for recent completion records, daily coin history, and full-clear streaks.
- Added a virtual shop panel where users can buy and equip pet accessories.
- Added local state fields for day records, coin balance, owned accessories, and equipped accessory.
- Added a default daily fitness task template for healthier student/researcher routines.
- Kept reward data local-only; no network sync, background tracking, or activity monitoring.

## 0.1.0 - 2026-06-03

- Converted the single-file AppKit prototype into a GitHub-ready Swift project.
- Added a Swift Package layout and local `.app` release script.
- Preserved the transparent glass desktop widget visual style.
- Preserved `DeskWindow`, `FocusTextField`, `acceptsFirstMouse`, `focusInput()`, and desktop parking behavior.
- Added a Preferences window for:
  - task templates
  - repeat rules
  - daily appearance time
  - default pinned behavior
  - quick-open file and URL targets
- Moved hard-coded paths and default tasks into local `config.json`.
- Added a lightweight in-app daily appearance timer while the app is running.
- Added auto-growing task window height and a transparent scroll view for longer task lists.
- Added App Store readiness notes and release packaging docs.
