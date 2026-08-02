# iOS Build Scripts

**Production-ready bash scripts for an Xcode build, test, and release pipeline.**

Originally written for a Bitrise / Xcode CI setup. App names are the placeholder **`MyApp`**; paths and secrets come from **environment variables**. Every script uses `set -euo pipefail` and a clear header (`Description` / `Usage` / `Requirements`).

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-green.svg)](#)
[![CI](https://img.shields.io/badge/CI-Bitrise%20example-purple.svg)](examples/bitrise-example.yml)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](#)

---

## Why this exists

| Problem | What these scripts do |
|---------|------------------------|
| Ad-hoc CI copy-paste that drifts per project | One configurable set of scripts with env overrides |
| Absolute paths and real app names in git | `MyApp` placeholders + `PROJECT_ROOT` / `APPLICATION_NAME` |
| Fragile `xcodebuild` pipelines | `set -euo pipefail`, status capture around `xcpretty`, simulator cleanup via `trap` |
| Crashlytics / versioning only in Xcode lore | Drop-in Run Script phases documented in one place |

Full integration guide: **[docs/usage.md](docs/usage.md)**  
Bitrise sample: **[examples/bitrise-example.yml](examples/bitrise-example.yml)**

---

## What’s inside

```text
ios-build-scripts/
├── docs/usage.md
├── examples/bitrise-example.yml
└── scripts/
    ├── archive/appArchive.sh
    ├── build/automationBuild.sh
    ├── build/runUnitTests.sh
    ├── crashlytics/runCrashlytics.sh      # CocoaPods
    ├── crashlytics/runCrashlyticsSPM.sh   # SPM helpers
    ├── versioning/updateVersion.sh
    └── versioning/updateOmnitureRSIDs.sh
```

| Script | Role |
|--------|------|
| **[archive/appArchive.sh](scripts/archive/appArchive.sh)** | Release archive → Ad-Hoc IPA → Firebase App Distribution + dSYMs |
| **[build/automationBuild.sh](scripts/build/automationBuild.sh)** | Debug simulator build in a disposable clone; zips the `.app` |
| **[build/runUnitTests.sh](scripts/build/runUnitTests.sh)** | Unit tests in a disposable sim; optional xcpretty JUnit + slather |
| **[crashlytics/runCrashlytics.sh](scripts/crashlytics/runCrashlytics.sh)** | Xcode Run Script: upload dSYMs (CocoaPods FirebaseCrashlytics) |
| **[crashlytics/runCrashlyticsSPM.sh](scripts/crashlytics/runCrashlyticsSPM.sh)** | Xcode Run Script: upload dSYMs (project-local SPM helpers) |
| **[versioning/updateVersion.sh](scripts/versioning/updateVersion.sh)** | Append git rev count to `CFBundleVersion` (non–App Store) |
| **[versioning/updateOmnitureRSIDs.sh](scripts/versioning/updateOmnitureRSIDs.sh)** | QA → prod Adobe Analytics RSID on App Store builds |

---

## Quick start

### 1. Install into your app

Copy `scripts/` under the Xcode project root so default path resolution works:

```text
MyApp/                          # PROJECT_ROOT
├── MyApp.xcodeproj
├── exportPlist.plist           # for Ad-Hoc export
└── scripts/
    ├── archive/
    ├── build/
    ├── crashlytics/
    └── versioning/
```

If the package lives elsewhere, set `PROJECT_ROOT` explicitly.

### 2. Unit tests

```bash
export PROJECT_ROOT="$(pwd)"
export APPLICATION_NAME=MyApp
./scripts/build/runUnitTests.sh
```

### 3. Automation `.app` zip

```bash
./scripts/build/automationBuild.sh
# → scripts/build/build/Debug-iphonesimulator/MyApp-debug.zip
```

### 4. Archive + Firebase (secrets required)

```bash
export FIREBASE_TOKEN="…"      # firebase login:ci
export FIREBASE_APP_ID="1:…:ios:…"
./scripts/archive/appArchive.sh
```

### 5. Xcode Run Script phases

```bash
"${SRCROOT}/scripts/versioning/updateVersion.sh"
"${SRCROOT}/scripts/versioning/updateOmnitureRSIDs.sh"   # after CocoaPods embed
"${SRCROOT}/scripts/crashlytics/runCrashlytics.sh"       # or runCrashlyticsSPM.sh
```

---

## Configuration (env vars)

| Variable | Default | Used by |
|----------|---------|---------|
| `PROJECT_ROOT` | two levels above `scripts/<category>/` | archive, build |
| `APPLICATION_NAME` | `MyApp` | most scripts |
| `SCHEME_NAME` | `$APPLICATION_NAME` or `…Tests` | archive, build |
| `PROJECT_NAME` | `$APPLICATION_NAME.xcodeproj` | archive, build |
| `FIREBASE_TOKEN` | **required** | `appArchive.sh` |
| `FIREBASE_APP_ID` | **required** | `appArchive.sh` |
| `FIREBASE_GROUPS` | `ios_testers` | `appArchive.sh` |
| `BASE_SIM` / `TEST_DEVICE` | `UnitTestDevice15` | automation / tests |
| `SIM_OS` | `15.0` | automation / tests |
| `TEMP_SIM` | `true` | `runUnitTests.sh` |
| `XCPRETTY` | `true` | `runUnitTests.sh` |
| `SLATHER` | `false` | `runUnitTests.sh` |
| `OMNITURE_QA_RSID` / `OMNITURE_PROD_RSID` | `myappmobile-qa` / `myappmobile` | Omniture script |
| `EXTENSION_NAME` | `notificationservice` | `updateVersion.sh` |

---

## Requirements

- Xcode CLT (`xcodebuild`, `xcrun`, `simctl`)
- [xcpretty](https://github.com/xcpretty/xcpretty)
- [Firebase CLI](https://firebase.google.com/docs/cli) (App Distribution)
- [slather](https://github.com/SlatherOrg/slather) (optional coverage)
- A base simulator (e.g. `UnitTestDevice15`) or override via env

---

## License

[MIT](LICENSE) — Copyright (c) 2021–2026 Juan Carlos Correa Arango

## Author

**Juan Correa** ([@serenoj](https://github.com/serenoj))

## Related repos

| Repo | Relation |
|------|----------|
| [accessibility-helper](https://github.com/serenoj/accessibility-helper) | Accessibility IDs + UI test scaffolding |
| [ios-analysis-toolkit](https://github.com/serenoj/ios-analysis-toolkit) | Periphery + Sourcery analysis |
