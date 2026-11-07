#!/bin/bash
# Runs the integration tests on the running emulator. The test installs the app itself, so access to
# photos is granted as soon as it appears, instead of a dialog nobody can answer.
set -u

(
	while true; do
		for permission in READ_MEDIA_IMAGES READ_MEDIA_VIDEO ACCESS_MEDIA_LOCATION POST_NOTIFICATIONS; do
			adb shell pm grant app.mediarr.mediarr "android.permission.$permission" >/dev/null 2>&1
		done
		sleep 2
	done
) &
grants=$!
trap 'kill "$grants" 2>/dev/null' EXIT

adb logcat -c
adb logcat '*:W' >/tmp/emulator.log &
flutter test integration_test -d emulator-5554 --suppress-analytics --reporter expanded --timeout 8m
status=$?
echo '--- last warnings from the emulator ---'
grep -iE 'mediarr|backup|AndroidRuntime|WM-' /tmp/emulator.log | tail -60

# The tests run a debug build; people install the release one. It must at least start.
echo '--- the release build starts ---'
adb uninstall app.mediarr.mediarr >/dev/null 2>&1
flutter build apk --release --suppress-analytics >/tmp/release-build.log 2>&1 || { tail -30 /tmp/release-build.log; exit 1; }
# Built unsigned, as the server signs it; a key made here for the run is enough to install it.
keytool -genkeypair -keystore /tmp/ci.jks -storepass android -keypass android -alias ci -dname CN=ci \
	-keyalg RSA -keysize 2048 -validity 1 >/dev/null 2>&1 || exit 1
signer="$(ls -d "$ANDROID_HOME"/build-tools/*/ | sort -V | tail -1)apksigner"
"$signer" sign --ks /tmp/ci.jks --ks-pass pass:android --key-pass pass:android \
	--ks-key-alias ci --out /tmp/release-signed.apk build/app/outputs/flutter-apk/app-release.apk || exit 1
adb install -r /tmp/release-signed.apk || exit 1
adb logcat -c
adb shell monkey -p app.mediarr.mediarr -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 15
if adb shell pidof app.mediarr.mediarr >/dev/null; then
	echo 'the release build is running'
else
	echo 'THE RELEASE BUILD STOPPED ON START:'
	adb logcat -d | grep -E -A60 'FATAL EXCEPTION|AndroidRuntime|F flutter|E flutter|libc  .*Fatal' | head -120
	status=1
fi
exit "$status"
