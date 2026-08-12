#!/bin/sh

# Xcode Cloud runs this automatically after cloning the repo, before any
# build action. Sets CURRENT_PROJECT_VERSION to Xcode Cloud's own build
# number ($CI_BUILD_NUMBER) so every archive gets a build number that's
# actually unique in App Store Connect.
#
# Without this, the project's checked-in CURRENT_PROJECT_VERSION was a
# static "1" that never changed between commits, so every single archive
# produced the exact same (MARKETING_VERSION, CURRENT_PROJECT_VERSION) pair
# — every upload after the very first one collided with it in App Store
# Connect instead of creating a new, selectable build.

set -e

cd "$CI_PRIMARY_REPOSITORY_PATH"
xcrun agvtool new-version -all "$CI_BUILD_NUMBER"
