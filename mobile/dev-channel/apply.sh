#!/bin/bash
# Turns this checkout into Mediarr Dev, which installs beside the stable app. Runs in CI, never commit its result.
set -euo pipefail
cd "$(dirname "$0")/.."
cp dev-channel/ios/AppIcon.appiconset/*.png ios/Runner/Assets.xcassets/AppIcon.appiconset/
for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  cp "dev-channel/android/mipmap-$density/ic_launcher.png" "android/app/src/main/res/mipmap-$density/"
done
perl -pi -e 's/PRODUCT_BUNDLE_IDENTIFIER = app\.mediarr\.mediarr;/PRODUCT_BUNDLE_IDENTIFIER = app.mediarr.mediarr.dev;/' ios/Runner.xcodeproj/project.pbxproj
perl -0pi -e 's#(<key>CFBundleDisplayName</key>\s*<string>)Mediarr(</string>)#$1Mediarr Dev$2#; s#(<key>CFBundleName</key>\s*<string>)Mediarr(</string>)#$1Mediarr Dev$2#' ios/Runner/Info.plist
perl -pi -e 's/applicationId = "app\.mediarr\.mediarr"/applicationId = "app.mediarr.mediarr.dev"/' android/app/build.gradle*
perl -pi -e 's/android:label="Mediarr"/android:label="Mediarr Dev"/' android/app/src/main/AndroidManifest.xml
# Android 8 and later draw the adaptive icon, not the files above: Dev has the fan on gold.
perl -pi -e 's#<color name="ic_launcher_background">\#FFFFFF</color>#<color name="ic_launcher_background">\#FFC83D</color>#' android/app/src/main/res/values/colors.xml
grep -q 'app.mediarr.mediarr.dev;' ios/Runner.xcodeproj/project.pbxproj
grep -q 'Mediarr Dev' ios/Runner/Info.plist
grep -q 'app.mediarr.mediarr.dev' android/app/build.gradle*
grep -q 'Mediarr Dev' android/app/src/main/AndroidManifest.xml
grep -q '#FFC83D' android/app/src/main/res/values/colors.xml
