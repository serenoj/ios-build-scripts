#!/bin/bash
# Description: Clean-builds a Debug simulator build in a disposable simulator
#   clone and zips the resulting .app for UI automation pipelines.
# Usage: ./automationBuild.sh
#   Optional: PROJECT_ROOT=/path/to/MyApp APPLICATION_NAME=MyApp
#             BASE_SIM=UnitTestDevice15 SIM_OS=15.0
# Requirements: xcodebuild, xcpretty, xcrun simctl; a base simulator named
#   BASE_SIM (default UnitTestDevice15) must already exist.

set -euo pipefail

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

APPLICATION_NAME="${APPLICATION_NAME:-MyApp}"
SCHEME_NAME="${SCHEME_NAME:-${APPLICATION_NAME}}"
PROJECT_NAME="${PROJECT_NAME:-${APPLICATION_NAME}.xcodeproj}"
CONFIGURATION_NAME="${CONFIGURATION_NAME:-Debug}"
# Simulator SDK (not device) — product lands under Debug-iphonesimulator.
TARGET_SDK="${TARGET_SDK:-iphonesimulator}"
BASE_SIM="${BASE_SIM:-UnitTestDevice15}"
SIM_OS="${SIM_OS:-15.0}"
PACKAGEMANAGER="${PACKAGEMANAGER:-${PROJECT_ROOT}/SourcePackages}"

TIMECODE="$(date +"%H%M%S")"
BUILD_SIM="${BASE_SIM}_${TIMECODE}"
DESTINATION="platform=iOS Simulator,name=${BUILD_SIM},OS=${SIM_OS}"
DERIVED_DATA_PATH="${PROJECT_ROOT}/DerivedData"
PROJECT_DEBUG_BUILDDIR="${DERIVED_DATA_PATH}/Build/Products/Debug-iphonesimulator"
OUTPUT_DIR="Debug-iphonesimulator"
OUTPUT_PATH="${SCRIPT_DIR}/build/${OUTPUT_DIR}"

cleanup() {
  if xcrun simctl list devices | grep -q "${BUILD_SIM}"; then
    xcrun simctl delete "${BUILD_SIM}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "Automation build for ${APPLICATION_NAME}"
echo "PROJECT_ROOT=${PROJECT_ROOT}"

rm -rf "${DERIVED_DATA_PATH}" "${SCRIPT_DIR}/build"
mkdir -p "${OUTPUT_PATH}"

echo "Creating temporary simulator: ${BUILD_SIM}"
xcrun simctl clone "${BASE_SIM}" "${BUILD_SIM}" >/dev/null

cd "${PROJECT_ROOT}"

echo "Starting Debug build..."
set +e
xcrun -k xcodebuild \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  -project "${PROJECT_NAME}" \
  -scheme "${SCHEME_NAME}" \
  -sdk "${TARGET_SDK}" \
  -configuration "${CONFIGURATION_NAME}" \
  -destination "${DESTINATION}" \
  clean build \
  2> "${SCRIPT_DIR}/build_errors.log" \
  | xcpretty
BUILD_STATUS=${PIPESTATUS[0]}
set -e

if [ "${BUILD_STATUS}" -ne 0 ]; then
  echo "Build failed (status ${BUILD_STATUS}). See ${SCRIPT_DIR}/build_errors.log" >&2
  exit "${BUILD_STATUS}"
fi

APP_PATH="${PROJECT_DEBUG_BUILDDIR}/${APPLICATION_NAME}.app"
if [ ! -d "${APP_PATH}" ]; then
  echo "Debug .app not found at ${APP_PATH}" >&2
  exit 1
fi

echo "Zipping Debug .app..."
(
  cd "${PROJECT_DEBUG_BUILDDIR}"
  zip -rq "${OUTPUT_PATH}/${APPLICATION_NAME}-debug.zip" "${APPLICATION_NAME}.app"
)

echo "Debug build zip: ${OUTPUT_PATH}/${APPLICATION_NAME}-debug.zip"
