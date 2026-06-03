# Release Packaging

## Local unsigned build

```bash
./Scripts/build-release.sh
open Build/DailyDesk.app
```

## GitHub Release draft

Recommended release assets:

- `DailyDesk.app.zip`
- screenshot from `Screenshots/dailydesk_refined_2.png`
- release notes copied from `CHANGELOG.md`

Create the zip:

```bash
cd Build
ditto -c -k --keepParent DailyDesk.app DailyDesk-0.1.0-macOS.zip
```

## Developer ID distribution later

For public distribution outside the Mac App Store, use a Developer ID certificate and notarization.

Approximate future flow:

```bash
codesign --force --deep --options runtime --sign "Developer ID Application: TEAM" Build/DailyDesk.app
ditto -c -k --keepParent Build/DailyDesk.app DailyDesk.zip
xcrun notarytool submit DailyDesk.zip --keychain-profile PROFILE --wait
xcrun stapler staple Build/DailyDesk.app
```

This requires a paid Apple Developer account and a properly configured signing identity.

## Mac App Store later

The current local packaging script is not the final App Store submission path. For App Store submission:

- create or generate an Xcode app target
- enable App Sandbox
- configure entitlements
- archive from Xcode
- submit through App Store Connect

