# Usage guide — ios-build-scripts

How to wire these scripts into an Xcode project and CI. App name, paths, and
secrets are placeholders; override them for your app.

## Recommended project layout

Copy the contents of `scripts/` into your app repo so the default
`PROJECT_ROOT` resolution works (two levels up from `scripts/<category>/`):

```text
MyApp/                                 # PROJECT_ROOT / git root
├── MyApp.xcodeproj
├── MyApp/
│   └── Supporting Files/
│       └── GoogleService-Info.plist
├── exportPlist.plist                  # for Ad-Hoc export (appArchive)
├── SourcePackages/                    # optional SPM clone dir
└── scripts/
    ├── upload-symbols                 # Firebase Crashlytics helper (if SPM path)
    ├── runFirebase                    # optional SPM run helper
    ├── archive/
    │   └── appArchive.sh
    ├── build/
    │   ├── automationBuild.sh
    │   └── runUnitTests.sh
    ├── crashlytics/
    │   ├── runCrashlytics.sh
    │   └── runCrashlyticsSPM.sh
    └── versioning/
        ├── updateVersion.sh
        └── updateOmnitureRSIDs.sh
```

If you keep this repo nested (e.g. `MyApp/ios-build-scripts/scripts/...`),
always set `PROJECT_ROOT` explicitly to the Xcode project root.

## Prerequisites

| Tool | Needed for |
|------|------------|
| Xcode CLT (`xcodebuild`, `xcrun`, `simctl`) | all CI scripts |
| [xcpretty](https://github.com/xcpretty/xcpretty) | archive, automation build, unit tests |
| [Firebase CLI](https://firebase.google.com/docs/cli) | App Distribution (`appArchive.sh`) |
| [slather](https://github.com/SlatherOrg/slather) | optional coverage (`SLATHER=true`) |
| Base simulator (e.g. `UnitTestDevice15`) | automation + unit tests |

Create a named simulator once on the machine/image, for example:

```bash
xcrun simctl create UnitTestDevice15 \
  "iPhone 13" \
  com.apple.CoreSimulator.SimRuntime.iOS-15-0
```

Adjust device type and runtime to match your `SIM_OS` / Xcode version.

## Environment variables

| Variable | Default | Notes |
|----------|---------|--------|
| `PROJECT_ROOT` | `scripts/<category>/../../` | Override when layout differs |
| `APPLICATION_NAME` | `MyApp` | Target / product name |
| `SCHEME_NAME` | `$APPLICATION_NAME` or `…Tests` | Per-script default |
| `PROJECT_NAME` | `$APPLICATION_NAME.xcodeproj` | Use `.xcworkspace` only if you change scripts |
| `FIREBASE_TOKEN` | _(required)_ | `firebase login:ci` token — CI secret only |
| `FIREBASE_APP_ID` | _(required)_ | Firebase iOS app id — CI secret/config |
| `FIREBASE_GROUPS` | `ios_testers` | App Distribution tester groups |
| `BASE_SIM` / `TEST_DEVICE` | `UnitTestDevice15` | Base sim to clone |
| `SIM_OS` | `15.0` | Must match an installed runtime |
| `TEMP_SIM` | `true` | Clone + delete disposable sim |
| `XCPRETTY` | `true` | JUnit under DerivedData when true |
| `SLATHER` | `false` | Coverage after green tests |
| `OMNITURE_QA_RSID` | `myappmobile-qa` | Replaced on App Store builds |
| `OMNITURE_PROD_RSID` | `myappmobile` | Production suite id |
| `EXTENSION_NAME` | `notificationservice` | Optional appex in `updateVersion.sh` |

Xcode Run Script phases also receive standard build settings (`SRCROOT`,
`CONFIGURATION`, `TARGET_BUILD_DIR`, `PODS_ROOT`, `DWARF_DSYM_*`,
`MARKETING_VERSION`, `TARGET_NAME`, …).

## Local / CI invocation

From the **project root** (or with `PROJECT_ROOT` set):

```bash
# Unit tests
./scripts/build/runUnitTests.sh

# UI-automation .app zip
./scripts/build/automationBuild.sh

# Release archive + Firebase (secrets required)
export FIREBASE_TOKEN="…"
export FIREBASE_APP_ID="1:1234567890:ios:abcdef"
./scripts/archive/appArchive.sh
```

Custom names:

```bash
export APPLICATION_NAME=MyApp
export SCHEME_NAME=MyApp
export PROJECT_ROOT="$(pwd)"
export TEST_DEVICE=UnitTestDevice15
export SIM_OS=17.0
./scripts/build/runUnitTests.sh
```

## Xcode Run Script phases

Add these as **Run Script** build phases (target → Build Phases). Prefer
calling the shell file rather than pasting the body, so updates stay in git.

### Version stamp (Debug / QA)

Shell:

```bash
"${SRCROOT}/scripts/versioning/updateVersion.sh"
```

Runs for every configuration except `App Store Distribution`. Updates
`CFBundleVersion` to `${MARKETING_VERSION}.${git_rev}` on the main app and
optional notification extension.

### Omniture RSID swap (App Store only)

Place **after** CocoaPods embed phases:

```bash
"${SRCROOT}/scripts/versioning/updateOmnitureRSIDs.sh"
```

### Crashlytics dSYMs

**CocoaPods:**

```bash
"${SRCROOT}/scripts/crashlytics/runCrashlytics.sh"
```

**SPM helpers** (expects `scripts/runFirebase` + `scripts/upload-symbols`):

```bash
"${SRCROOT}/scripts/crashlytics/runCrashlyticsSPM.sh"
```

Both run only when `CONFIGURATION` is `Release` or `App Store Distribution`.

Optional overrides in the phase (or xcconfig):

```bash
export APPLICATION_NAME=MyApp
# export GSP_PATH="${SRCROOT}/MyApp/Supporting Files/GoogleService-Info.plist"
```

## Bitrise

See [`examples/bitrise-example.yml`](../examples/bitrise-example.yml) for a
full sample with three workflows:

1. **primary** — unit tests on PR / push  
2. **automation_build** — Debug `.app` zip for UI automation  
3. **distribute** — archive, Ad-Hoc export, Firebase App Distribution  

Map secrets in the Bitrise UI (never commit them):

- `FIREBASE_TOKEN`
- `FIREBASE_APP_ID` (or store as app env if non-secret)

Ensure the stack has your base simulator, xcpretty, and Firebase CLI (install
steps in the example YAML).

## Conventions used by every script

- `#!/bin/bash` and `set -euo pipefail`
- Header block: Description, Usage, Requirements
- No hardcoded absolute paths; secrets via env
- Placeholder product name: `MyApp`

## Troubleshooting

| Symptom | Check |
|---------|--------|
| Wrong project / missing `.xcodeproj` | Set `PROJECT_ROOT`; confirm layout under `scripts/<category>/` |
| Simulator not found | Create `TEST_DEVICE` / `BASE_SIM`; align `SIM_OS` with runtime |
| `FIREBASE_TOKEN: unbound` / required message | Export token before `appArchive.sh` |
| Archive ok, export fails | `exportPlist.plist` path and signing identities |
| Crashlytics phase no-op | Configuration name must match `Release` or `App Store Distribution` exactly |
| `set -u` failure in Run Script | Script ran outside Xcode without build settings — expected |

For a short overview of scripts and variables, see the root [README](../README.md).
