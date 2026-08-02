#!/bin/bash
# Description: Xcode "Run Script" build phase that swaps the Adobe Analytics
#   (Omniture) QA report suite ID for the production ID in ADBMobileConfig.json
#   on App Store builds.
# Usage: Add as a Run Script phase AFTER CocoaPods embed phases. Relies on
#   Xcode env vars: CONFIGURATION, TARGET_BUILD_DIR.
#   Optional: APPLICATION_NAME=MyApp OMNITURE_QA_RSID=... OMNITURE_PROD_RSID=...
# Requirements: /usr/bin/sed; ADBMobileConfig.json embedded in the app bundle.

set -euo pipefail

APPLICATION_NAME="${APPLICATION_NAME:-MyApp}"
OMNITURE_QA_RSID="${OMNITURE_QA_RSID:-myappmobile-qa}"
OMNITURE_PROD_RSID="${OMNITURE_PROD_RSID:-myappmobile}"

if [ "${CONFIGURATION:-}" != "App Store Distribution" ]; then
  exit 0
fi

FILE="${TARGET_BUILD_DIR}/${APPLICATION_NAME}.app/ADBMobileConfig.json"
if [ -f "${FILE}" ]; then
  /usr/bin/sed -i '' -e "s/${OMNITURE_QA_RSID}/${OMNITURE_PROD_RSID}/" "${FILE}"
  echo "Updated Omniture RSID in ${FILE}"
fi
