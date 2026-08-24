#!/bin/sh
# Xcode Cloud: stamp the build number as <marketing version>.<cloud build number>
# (e.g. 1.1.0.14), Svea-Pay style, so builds visibly belong to their release.
set -e
if [ -n "$CI_BUILD_NUMBER" ]; then
  cd "$CI_PRIMARY_REPOSITORY_PATH"
  MARKETING=$(grep -m1 'MARKETING_VERSION = ' OneF.xcodeproj/project.pbxproj | sed 's/.*= *\(.*\);/\1/')
  NEW="$MARKETING.$CI_BUILD_NUMBER"
  sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $NEW;/g" OneF.xcodeproj/project.pbxproj
  echo "OneF build number stamped: $NEW"
fi
