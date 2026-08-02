#!/bin/bash
# Description: Xcode "Run Script" build phase that appends the git revision
#   count to CFBundleVersion for non–App Store builds (main app + optional
#   notification service extension).
# Usage: Add as a Run Script phase in Xcode. Relies on Xcode env vars:
#   CONFIGURATION, TARGET_NAME, TARGET_BUILD_DIR, MARKETING_VERSION.
#   Optional: APPLICATION_NAME=MyApp EXTENSION_NAME=notificationservice
# Requirements: git; /usr/libexec/PlistBuddy; run from a git working tree.

set -euo pipefail

APPLICATION_NAME="${APPLICATION_NAME:-MyApp}"
EXTENSION_NAME="${EXTENSION_NAME:-notificationservice}"

if [ "${CONFIGURATION:-}" = "App Store Distribution" ]; then
  exit 0
fi

REV="$(git rev-list HEAD | wc -l | tr -d '[:space:]')"
echo "Setting CFBundleVersion to ${MARKETING_VERSION}.${REV} (${CONFIGURATION}, target ${TARGET_NAME})"

if [ "${TARGET_NAME}" = "${APPLICATION_NAME}" ] && [ -f "${TARGET_BUILD_DIR}/${APPLICATION_NAME}.app/Info.plist" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${MARKETING_VERSION}.${REV}" \
    "${TARGET_BUILD_DIR}/${APPLICATION_NAME}.app/Info.plist"
fi

if [ "${TARGET_NAME}" = "${EXTENSION_NAME}" ] && [ -f "${TARGET_BUILD_DIR}/${EXTENSION_NAME}.appex/Info.plist" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${MARKETING_VERSION}.${REV}" \
    "${TARGET_BUILD_DIR}/${EXTENSION_NAME}.appex/Info.plist"
fi
