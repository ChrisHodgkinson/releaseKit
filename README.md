# GameMaker macOS Release Tool

A Bash-based release pipeline for building signed, notarized, Gatekeeper-friendly macOS releases from a GameMaker `.app` export.

The tool copies a GameMaker-built application into a clean release folder, signs it with a Developer ID certificate, submits it to Apple for notarization, staples the notarization ticket, verifies it with Gatekeeper, creates a ZIP archive, and builds a polished drag-to-Applications DMG.

It can be adapted for any GameMaker macOS project by editing `config.sh`.

---

## What it does

The release script performs the full macOS release flow:

```text
GameMaker .app
→ copy to a clean release folder
→ sign embedded Mach-O binaries
→ sign the app bundle
→ verify code signature
→ create ZIP archive
→ submit to Apple notarization
→ staple notarization ticket
→ verify with Gatekeeper
→ create polished DMG
→ write release report
```

The DMG step can also apply a custom background image, Finder window size, icon size, and icon placement.

---

## Project structure

```text
release/
├── release.sh
├── config.sh
├── assets/
│   └── dmg-background.png
├── lib/
│   ├── archive.sh
│   ├── checks.sh
│   ├── colours.sh
│   ├── dmg.sh
│   ├── notarize.sh
│   ├── report.sh
│   ├── signing.sh
│   ├── util.sh
│   └── version.sh
└── Releases/
```

Release output folders are created inside:

```text
release/Releases/
```

Each release gets its own versioned folder, for example:

```text
MyGame-v1.0.0/
├── MyGame.app
├── MyGame-v1.0.0-mac.zip
├── MyGame-v1.0.0.dmg
├── release-report.txt
└── .build/
```

---

## Requirements

This tool is intended for macOS.

You need:

- Xcode installed
- Apple Developer account
- Developer ID Application certificate installed in Keychain
- A saved `notarytool` keychain profile
- A GameMaker macOS `.app` build

Required command-line tools:

```text
xcodebuild
codesign
ditto
spctl
security
plutil
xcrun
hdiutil
osascript
```

---

## Important workflow note

Do **not** sign, notarize, or staple the GameMaker development output directly.

GameMaker should produce the app wherever `SOURCE_APP_PATH` points.

The release tool copies that `.app` into a separate release folder first, then signs and notarizes the copy.

This keeps the GameMaker build output clean and avoids breaking future test runs from GameMaker.

---

## Configuration

Edit:

```text
release/config.sh
```

Example configuration:

```bash
GAME_NAME="MyGame"
BUNDLE_ID="com.example.mygame"

SOURCE_APP_PATH="/Users/yourname/path/to/GameMakerBuild/MyGame.app"

RELEASE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Releases"

DEVELOPER_ID="Developer ID Application: Your Name (TEAMID1234)"
TEAM_ID="TEAMID1234"

NOTARY_PROFILE="notary-profile"

DMG_VOLUME_NAME="MyGame"

DMG_BACKGROUND_IMAGE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assets/dmg-background.png"
```

### Main values to change

| Setting | Purpose |
|---|---|
| `GAME_NAME` | The public name of your game. |
| `BUNDLE_ID` | The app bundle identifier used for signing/notarization. |
| `SOURCE_APP_PATH` | Path to the `.app` exported by GameMaker. |
| `RELEASE_ROOT` | Where release folders are created. |
| `DEVELOPER_ID` | Your Developer ID Application certificate name. |
| `TEAM_ID` | Your Apple Developer Team ID. |
| `NOTARY_PROFILE` | The saved `notarytool` keychain profile. |
| `DMG_VOLUME_NAME` | The name shown when the DMG is mounted. |
| `DMG_BACKGROUND_IMAGE` | Optional DMG background image. |

---

## Notary profile setup

Before using the release tool, create a saved notary profile using Apple’s `notarytool`.

Example:

```bash
xcrun notarytool store-credentials "notary-profile" \
    --apple-id "your-apple-id@example.com" \
    --team-id "YOURTEAMID" \
    --password "app-specific-password"
```

The profile name must match the value in `config.sh`:

```bash
NOTARY_PROFILE="notary-profile"
```

---

## DMG background image

The DMG background image should be placed here:

```text
release/assets/dmg-background.png
```

The DMG script copies it into the mounted DMG before applying the Finder layout.

Recommended background design:

- simple
- low contrast
- no text
- no logo
- enough empty space for icons and labels
- not too busy behind filenames

---

## Running a release

From inside the `release` folder:

```bash
./release.sh
```

The script asks for a version number:

```text
Version (e.g. 1.2.3):
```

Use semantic version format:

```text
1.0.0
1.2.3
2.0.0
```

A new release folder will be created using that version.

---

## Output

A successful release creates:

### Signed app

```text
MyGame-vX.Y.Z/MyGame.app
```

### ZIP archive for notarization/distribution

```text
MyGame-vX.Y.Z/MyGame-vX.Y.Z-mac.zip
```

### Polished DMG

```text
MyGame-vX.Y.Z/MyGame-vX.Y.Z.dmg
```

### Release report

```text
MyGame-vX.Y.Z/release-report.txt
```

The report includes version information, signing details, archive checksum, notarization status, and generated files.

---

## Spinner

Long-running commands use a terminal spinner with elapsed time.

This is especially useful for Apple notarization, because `notarytool submit --wait` can appear to pause while uploading and waiting for Apple to process the app.

The spinner does not show upload percentage; it simply confirms that the command is still running.

---

## Troubleshooting

### GameMaker app is missing

Check `SOURCE_APP_PATH` in `config.sh`.

The script expects the GameMaker-built `.app` to already exist before release begins.

### Developer ID certificate not found

Check the certificate name:

```bash
security find-identity -v -p codesigning
```

Make sure `DEVELOPER_ID` in `config.sh` exactly matches the Developer ID Application certificate.

### Notarization fails

Check the JSON file inside the release folder’s `.build` directory.

Example:

```text
MyGame-v1.0.0/.build/notarization.json
```

Common causes include:

- wrong signing certificate
- missing hardened runtime
- unsigned embedded Mach-O files
- incorrect notary profile
- invalid bundle identifier

### `statusSummary` warning during notarization

Apple’s `notarytool` JSON does not always include `statusSummary`, especially when the submission is accepted.

If your script prints something like this:

```text
Could not extract value, error: No value at that key path or invalid key path: statusSummary
```

make sure `log_notarization()` redirects that lookup to `/dev/null` and uses a fallback such as:

```bash
SUMMARY=$(plutil -extract statusSummary raw "$NOTARY_JSON" 2>/dev/null)

if [[ -z "$SUMMARY" ]]
then
    SUMMARY="No issues reported"
fi
```

### DMG layout does not stick

Finder layout settings are saved into the DMG’s `.DS_Store` file.

The script should open the mounted DMG, apply the layout, wait, sync, and only then detach the image. If layout settings stop sticking, check that the mounted image is writable and that Finder is allowed to write `.DS_Store`.

### DMG background does not appear

Check that this file exists:

```text
release/assets/dmg-background.png
```

Also confirm that the DMG script calls `add_background_image` before `polish_finder_window`.

---

## Git safety checkpoint

After confirming the release tool works, commit it:

```bash
git add release
git commit -m "Add GameMaker macOS release pipeline"
```

---

## Future improvements

Possible additions:

- `--no-dmg`
- `--sign-only`
- `--notarize-only`
- automatic next-version suggestion
- custom DMG volume icon
- DMG checksum in the release report
- optional signing/notarization of the DMG itself

---

## License

Add your preferred licence here.
