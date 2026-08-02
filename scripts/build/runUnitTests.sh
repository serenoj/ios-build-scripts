#!/bin/bash
# Description: Clean-builds and runs the unit-test scheme in a disposable
#   simulator clone. Optional JUnit output via xcpretty and coverage via slather.
# Usage: ./runUnitTests.sh
#   Optional: PROJECT_ROOT=/path/to/MyApp APPLICATION_NAME=MyApp
#             TEST_DEVICE=UnitTestDevice15 SIM_OS=15.0
#             TEMP_SIM=true XCPRETTY=true SLATHER=false
# Requirements: xcodebuild, xcrun simctl; xcpretty (if XCPRETTY=true);
#   slather (if SLATHER=true); base simulator TEST_DEVICE must exist.

set -euo pipefail

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

APPLICATION_NAME="${APPLICATION_NAME:-MyApp}"
PROJ_NAME="${PROJECT_NAME:-${APPLICATION_NAME}.xcodeproj}"
SCHEME_NAME="${SCHEME_NAME:-${APPLICATION_NAME}Tests}"
CONFIGURATION_NAME="${CONFIGURATION_NAME:-Debug}"
TEST_DEVICE="${TEST_DEVICE:-UnitTestDevice15}"
SIM_OS="${SIM_OS:-15.0}"
TEMP_SIM="${TEMP_SIM:-true}"
XCPRETTY="${XCPRETTY:-true}"
SLATHER="${SLATHER:-false}"
PACKAGEMANAGER="${PACKAGEMANAGER:-${PROJECT_ROOT}/SourcePackages}"

DERIVED_DATA="${PROJECT_ROOT}/DerivedData"
BUILD_DIR="${DERIVED_DATA}/Build"
PRODUCTS_DIR="${BUILD_DIR}/Products"
PROFILE_DATA_DIR="${BUILD_DIR}/ProfileData"
INTERMEDIATES_DIR="${BUILD_DIR}/Intermediates.noindex"

FULL_START="$(date +"%s")"
TIMECODE="$(date +"%H%M%S")"
TEST_SIM="${TEST_DEVICE}"

cleanup() {
  if xcrun simctl list devices | grep -q "${TEST_SIM}"; then
    xcrun simctl shutdown "${TEST_SIM}" 2>/dev/null || true
    if [ "${TEMP_SIM}" = true ] && [ "${TEST_SIM}" != "${TEST_DEVICE}" ]; then
      xcrun simctl delete "${TEST_SIM}" 2>/dev/null || true
    fi
  fi
}
trap cleanup EXIT

if [ "${TEMP_SIM}" = true ]; then
  TEST_SIM="${TEST_DEVICE}_${TIMECODE}"
  echo "Creating temporary simulator: ${TEST_SIM}"
  xcrun simctl shutdown "${TEST_DEVICE}" 2>/dev/null || true
  xcrun simctl erase "${TEST_DEVICE}" 2>/dev/null || true
  xcrun simctl clone "${TEST_DEVICE}" "${TEST_SIM}" >/dev/null
fi

echo "Booting simulator: ${TEST_SIM}"
xcrun simctl erase "${TEST_SIM}" 2>/dev/null || true
xcrun simctl boot "${TEST_SIM}"

IPHONE_DESTINATION="platform=iOS Simulator,name=${TEST_SIM},OS=${SIM_OS}"

cd "${PROJECT_ROOT}"
rm -rf Coverage
xcrun -k xcodebuild -alltargets clean >/dev/null 2>&1 || true

SETUP_END="$(date +"%s")"
echo "Running tests for scheme ${SCHEME_NAME}..."

maybe_prettify() {
  if [ "${XCPRETTY}" = true ]; then
    mkdir -p "${BUILD_DIR}/reports"
    xcpretty -r junit --output "${BUILD_DIR}/reports/junit.xml"
  else
    cat
  fi
}

set +e
xcrun -k xcodebuild \
  -derivedDataPath "${DERIVED_DATA}" \
  -project "${PROJ_NAME}" \
  -scheme "${SCHEME_NAME}" \
  -clonedSourcePackagesDirPath "${PACKAGEMANAGER}" \
  -configuration "${CONFIGURATION_NAME}" \
  BUILD_ROOT="${PRODUCTS_DIR}" \
  BUILD_DIR="${PRODUCTS_DIR}" \
  SYMROOT="${PRODUCTS_DIR}" \
  OBJROOT="${INTERMEDIATES_DIR}" \
  TEMP_ROOT="${INTERMEDIATES_DIR}" \
  -destination "${IPHONE_DESTINATION}" \
  -destination-timeout 60 \
  -enableThreadSanitizer NO \
  -enableUndefinedBehaviorSanitizer NO \
  -enableCodeCoverage YES \
  test \
  2> "${SCRIPT_DIR}/test_build_errors.log" \
  | maybe_prettify
BUILD_STATUS=${PIPESTATUS[0]}
set -e

TEST_END="$(date +"%s")"

if [ "${BUILD_STATUS}" -ne 0 ]; then
  echo "Tests failed (status ${BUILD_STATUS}). See ${SCRIPT_DIR}/test_build_errors.log" >&2
  exit "${BUILD_STATUS}"
fi

if [ "${XCPRETTY}" = true ] && [ "${SLATHER}" = true ]; then
  echo "Building coverage report..."
  slather version
  slather coverage --build-directory "${PROFILE_DATA_DIR}"
fi

FULL_END="$(date +"%s")"
echo "Setup: $((SETUP_END - FULL_START))s | Tests: $((TEST_END - SETUP_END))s | Total: $((FULL_END - FULL_START))s"
