# Changelog

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
