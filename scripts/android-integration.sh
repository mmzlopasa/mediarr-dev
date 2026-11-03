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
exit "$status"
