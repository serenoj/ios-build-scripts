#!/bin/bash
# Description: Archives a Release build, exports an Ad-Hoc IPA, uploads it to
#   Firebase App Distribution, and uploads dSYMs to Firebase Crashlytics.
# Usage: From CI (or locally with secrets set):
#   FIREBASE_TOKEN=... FIREBASE_APP_ID=... ./appArchive.sh
#   Optional: PROJECT_ROOT=/path/to/MyApp APPLICATION_NAME=MyApp SCHEME_NAME=MyApp
# Requirements: xcodebuild, xcpretty, Firebase CLI, git; Firebase upload-symbols
#   binary at ${PROJECT_ROOT}/scripts/upload-symbols; exportPlist.plist at project root.

set -euo pipefail

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Default assumes project/scripts/archive/this.sh → project root is two levels up.
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

APPLICATION_NAME="${APPLICATION_NAME:-MyApp}"
SCHEME_NAME="${SCHEME_NAME:-${APPLICATION_NAME}}"
PROJECT_NAME="${PROJECT_NAME:-${APPLICATION_NAME}.xcodeproj}"
CONFIGURATION_NAME="${CONFIGURATION_NAME:-Release}"
TARGET_SDK="${TARGET_SDK:-iphoneos}"
ARCHIVE_NAME="${APPLICATION_NAME}.xcarchive"
PACKAGEMANAGER="${PACKAGEMANAGER:-SourcePackages}"
FIREBASE_GROUPS="${FIREBASE_GROUPS:-ios_testers}"
FIREBASE_TOKEN="${FIREBASE_TOKEN:?Set the FIREBASE_TOKEN environment variable}"
FIREBASE_APP_ID="${FIREBASE_APP_ID:?Set the FIREBASE_APP_ID environment variable}"

DERIVED_DATA_PATH="${PROJECT_ROOT}/DerivedData"
PROJECT_BUILD_DIR="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION_NAME}-iphoneos"
DIST_BUILD_DIR="${SCRIPT_DIR}/distribution"
ARCHIVE_PATH="${PROJECT_BUILD_DIR}/${ARCHIVE_NAME}"
FIREBASE_UPLOAD="${FIREBASE_UPLOAD:-${PROJECT_ROOT}/scripts/upload-symbols}"
GOOGLE_SERVICE_INFO="${GOOGLE_SERVICE_INFO:-${PROJECT_ROOT}/${APPLICATION_NAME}/Supporting Files/GoogleService-Info.plist}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-${PROJECT_ROOT}/exportPlist.plist}"
CHANGE_NOTES_FILE="${SCRIPT_DIR}/ioschangenotes.txt"

REV="$(git -C "${PROJECT_ROOT}" rev-list HEAD | wc -l | tr -d '[:space:]')"
CHANGES="$(git -C "${PROJECT_ROOT}" log -1 --pretty=format:'%s%n%n%b' || true)"

echo "Archiving ${APPLICATION_NAME} (${CONFIGURATION_NAME}) — git rev ${REV}"
echo "PROJECT_ROOT=${PROJECT_ROOT}"
echo "${CHANGES}" > "${CHANGE_NOTES_FILE}"

cd "${PROJECT_ROOT}"

echo "Compiling archive..."
set +e
xcrun -k xcodebuild \
  -project "${PROJECT_NAME}" \
  -scheme "${SCHEME_NAME}" \
  -clonedSourcePackagesDirPath "${PACKAGEMANAGER}" \
  -sdk "${TARGET_SDK}" \
  -configuration "${CONFIGURATION_NAME}" \
  -archivePath "${PROJECT_BUILD_DIR}/${APPLICATION_NAME}" \
  clean archive \
  2> "${SCRIPT_DIR}/archive_errors.log" \
  | xcpretty
BUILD_STATUS=${PIPESTATUS[0]}
set -e

if [ "${BUILD_STATUS}" -ne 0 ]; then
  echo "Archive failed (status ${BUILD_STATUS}). See ${SCRIPT_DIR}/archive_errors.log" >&2
  exit "${BUILD_STATUS}"
fi

echo "Exporting Ad-Hoc IPA..."
xcrun -k xcodebuild \
  -exportArchive \
  -exportOptionsPlist "${EXPORT_OPTIONS_PLIST}" \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${DIST_BUILD_DIR}"

echo "Uploading IPA to Firebase App Distribution..."
firebase appdistribution:distribute "${DIST_BUILD_DIR}/${APPLICATION_NAME}.ipa" \
  --app "${FIREBASE_APP_ID}" \
  --release-notes-file "${CHANGE_NOTES_FILE}" \
  --groups "${FIREBASE_GROUPS}" \
  --token "${FIREBASE_TOKEN}"

echo "Uploading dSYMs to Firebase Crashlytics..."
"${FIREBASE_UPLOAD}" \
  -gsp "${GOOGLE_SERVICE_INFO}" \
  -p ios "${ARCHIVE_PATH}/dSYMs" \
  --token "${FIREBASE_TOKEN}"

echo "Archive script complete."
