# iOS CI/Build Shell Scripts

Shell scripts for an Xcode project's build, test, and release pipeline
(originally written for a Bitrise/Xcode-based iOS CI setup). App-specific
names are placeholders (`MyApp`); paths and IDs are configurable via
environment variables.

## Layout

```text
ios-build-scripts/
├── README.md
├── docs/
│   └── usage.md                 # integration guide (Xcode + CI)
├── examples/
│   └── bitrise-example.yml      # sample Bitrise workflows
└── scripts/
    ├── archive/
    │   └── appArchive.sh
    ├── build/
    │   ├── automationBuild.sh
    │   └── runUnitTests.sh
    ├── crashlytics/
    │   ├── runCrashlytics.sh          # CocoaPods FirebaseCrashlytics
    │   └── runCrashlyticsSPM.sh       # project-local SPM helpers
    └── versioning/
        ├── updateVersion.sh
        └── updateOmnitureRSIDs.sh
```

When integrating into an app, place the contents of `scripts/` under the
project root as `MyApp/scripts/...` so the default `PROJECT_ROOT` resolution
(`script → category → scripts → project`) works without overrides.

Step-by-step setup (layout, env vars, Run Script phases, Bitrise): see
[`docs/usage.md`](docs/usage.md). CI sample: [`examples/bitrise-example.yml`](examples/bitrise-example.yml).

## Scripts

| Script | Role |
|--------|------|
| `archive/appArchive.sh` | Release archive → Ad-Hoc IPA → Firebase App Distribution + Crashlytics dSYMs |
| `build/automationBuild.sh` | Debug simulator build in a disposable clone; zips the `.app` for UI automation |
| `build/runUnitTests.sh` | Unit tests in a disposable simulator; optional xcpretty JUnit + slather coverage |
| `crashlytics/runCrashlytics.sh` | Xcode Run Script: upload dSYMs (CocoaPods) |
| `crashlytics/runCrashlyticsSPM.sh` | Xcode Run Script: upload dSYMs (SPM local helpers) |
| `versioning/updateVersion.sh` | Xcode Run Script: append git rev to `CFBundleVersion` (non–App Store) |
| `versioning/updateOmnitureRSIDs.sh` | Xcode Run Script: QA → prod Omniture RSID on App Store builds |

## Configuration

All scripts use `set -euo pipefail` and accept overrides via environment
variables. Common ones:

| Variable | Default | Used by |
|----------|---------|---------|
| `PROJECT_ROOT` | two levels above the script (`…/scripts/<category>/` → project) | archive, build |
| `APPLICATION_NAME` | `MyApp` | most scripts |
| `SCHEME_NAME` | `$APPLICATION_NAME` or `$APPLICATION_NAME`Tests | archive, build |
| `PROJECT_NAME` | `$APPLICATION_NAME.xcodeproj` | archive, build |
| `FIREBASE_TOKEN` | **required** | `appArchive.sh` |
| `FIREBASE_APP_ID` | **required** | `appArchive.sh` |
| `FIREBASE_GROUPS` | `ios_testers` | `appArchive.sh` |
| `BASE_SIM` / `TEST_DEVICE` | `UnitTestDevice15` | automation / unit tests |
| `SIM_OS` | `15.0` | automation / unit tests |
| `TEMP_SIM` | `true` | `runUnitTests.sh` |
| `XCPRETTY` | `true` | `runUnitTests.sh` |
| `SLATHER` | `false` | `runUnitTests.sh` |
| `OMNITURE_QA_RSID` | `myappmobile-qa` | `updateOmnitureRSIDs.sh` |
| `OMNITURE_PROD_RSID` | `myappmobile` | `updateOmnitureRSIDs.sh` |
| `EXTENSION_NAME` | `notificationservice` | `updateVersion.sh` |

Xcode Run Script phases also rely on standard build settings (`SRCROOT`,
`CONFIGURATION`, `TARGET_BUILD_DIR`, `PODS_ROOT`, `DWARF_DSYM_*`,
`MARKETING_VERSION`, etc.).

## Requirements

- Xcode command line tools (`xcodebuild`, `xcrun`, `simctl`)
- [`xcpretty`](https://github.com/xcpretty/xcpretty) (archive / build / tests)
- [Firebase CLI](https://firebase.google.com/docs/cli) (App Distribution)
- [`slather`](https://github.com/SlatherOrg/slather) (optional coverage)
- A base iOS Simulator named like `UnitTestDevice15` (or override via env)

## Author

Juan Correa
