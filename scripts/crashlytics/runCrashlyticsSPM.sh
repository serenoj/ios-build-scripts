#!/bin/bash
# Description: Xcode "Run Script" build phase that uploads dSYMs to Firebase
#   Crashlytics using project-local SPM helper binaries under scripts/.
# Usage: Add as a Run Script phase in Xcode (after compile). Relies on
#   Xcode-provided env vars: CONFIGURATION, SRCROOT, DWARF_DSYM_FOLDER_PATH,
#   DWARF_DSYM_FILE_NAME.
#   Optional override: APPLICATION_NAME=MyApp
# Requirements: ${SRCROOT}/scripts/runFirebase and upload-symbols binaries;
#   GoogleService-Info.plist at ${SRCROOT}/${APPLICATION_NAME}/Supporting Files/

set -euo pipefail

APPLICATION_NAME="${APPLICATION_NAME:-MyApp}"
GSP_PATH="${GSP_PATH:-${SRCROOT}/${APPLICATION_NAME}/Supporting Files/GoogleService-Info.plist}"
FIREBASE_RUN="${FIREBASE_RUN:-${SRCROOT}/scripts/runFirebase}"
FIREBASE_UPLOAD="${FIREBASE_UPLOAD:-${SRCROOT}/scripts/upload-symbols}"

if [ "${CONFIGURATION:-}" = "App Store Distribution" ] || [ "${CONFIGURATION:-}" = "Release" ]; then
  echo "Uploading dSYMs to Crashlytics via SPM helpers (${CONFIGURATION})"
  "${FIREBASE_RUN}"
  "${FIREBASE_UPLOAD}" \
    -gsp "${GSP_PATH}" \
    -p ios "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"
fi
