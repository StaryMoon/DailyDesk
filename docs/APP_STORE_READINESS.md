# Mac App Store Readiness

Checked against Apple official documentation on 2026-06-03.

## Current status

DailyDesk is good for a GitHub/open-source release, but it is not ready for Mac App Store submission yet.

The current repo intentionally avoids installing LaunchAgents automatically. The in-app daily appearance time uses a normal `Timer` only while the app is already running.

## Relevant Apple rules

Apple App Review Guidelines for macOS apps say apps submitted to the Mac App Store must be appropriately sandboxed, packaged as self-contained app bundles using Apple/Xcode technologies, and must not auto-launch or run code at startup/login without user consent.

Official references:

- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- App Sandbox: https://developer.apple.com/documentation/security/app_sandbox
- Configuring the macOS App Sandbox: https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox
- Service Management / SMAppService: https://developer.apple.com/documentation/servicemanagement/
- macOS distribution: https://developer.apple.com/macos/distribution/

## Sandbox implications

For Mac App Store:

- Enable `com.apple.security.app-sandbox`.
- Keep task data in the app container.
- Use user-selected file access for the AI briefing file.
- Persist file access with security-scoped bookmarks if the app needs to reopen the selected file later.
- Avoid broad filesystem assumptions such as hard-coded `~/Downloads/...` paths.
- Do not write into `~/Library/LaunchAgents` from the store build.

The repo includes `Resources/DailyDesk.entitlements` as a starting point, but it is not yet wired to a final Xcode archive flow.

## Daily auto-open strategy

The prototype used personal-machine LaunchAgents. That is acceptable for a local prototype, but should not be copied directly into the App Store build.

Recommended App Store path:

1. Add a user-visible setting such as "Open DailyDesk at login / daily reminder".
2. Use Apple's Service Management APIs, especially `SMAppService`, for a bundled helper/login item if daily launch-on-login behavior is needed.
3. Make the behavior opt-in and reversible.
4. Document it in review notes.
5. Avoid hidden background processes after the user quits the app.

DailyDesk should not implement continuous background monitoring. A helper, if added, should only launch/show the app at a user-approved time and then exit or stay minimal.

## Privacy statement draft

DailyDesk stores task data locally on this Mac. It does not create accounts, upload data, track app usage, monitor windows, or run analytics. The app opens external websites or local files only when the user clicks a quick-open button.

## Before App Store submission

- Add an Xcode project/app target or a reliable project generator.
- Wire entitlements into the archive build.
- Add security-scoped bookmarks for selected local files.
- Add a visible onboarding/privacy explanation.
- Add a reversible Login Item / daily open preference only after testing `SMAppService`.
- Prepare App Store screenshots and metadata.
- Test with a clean macOS user account.

