#!/bin/bash
# Description: Xcode "Run Script" build phase that uploads dSYMs to Firebase
#   Crashlytics using the CocoaPods-managed FirebaseCrashlytics tools.
# Usage: Add as a Run Script phase in Xcode (after compile). Relies on
#   Xcode-provided env vars: CONFIGURATION, SRCROOT, PODS_ROOT,
#   DWARF_DSYM_FOLDER_PATH, DWARF_DSYM_FILE_NAME.
#   Optional override: APPLICATION_NAME=MyApp
# Requirements: FirebaseCrashlytics via CocoaPods; GoogleService-Info.plist at
#   ${SRCROOT}/${APPLICATION_NAME}/Supporting Files/

set -euo pipefail

APPLICATION_NAME="${APPLICATION_NAME:-MyApp}"
GSP_PATH="${GSP_PATH:-${SRCROOT}/${APPLICATION_NAME}/Supporting Files/GoogleService-Info.plist}"

if [ "${CONFIGURATION:-}" = "App Store Distribution" ] || [ "${CONFIGURATION:-}" = "Release" ]; then
  echo "Uploading dSYMs to Crashlytics (${CONFIGURATION})"
  "${PODS_ROOT}/FirebaseCrashlytics/run"
  "${PODS_ROOT}/FirebaseCrashlytics/upload-symbols" \
    -gsp "${GSP_PATH}" \
    -p ios "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"
fi
