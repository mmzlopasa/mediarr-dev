"""Checks for scripts/pull-ipa.sh and scripts/pull-apk.sh, which publish CI builds on a public CDN.

  artifact.py run CHANNEL WORKFLOW < runs.json          the run to publish, or nothing
  artifact.py artifact NAME < artifacts.json            its download address, or nothing
  artifact.py extract ZIP MEMBER DEST MAX_BYTES         one file out of a zip, nothing else
  artifact.py ipa IPA BUNDLE_ID                         the app's version, if it is this app
  artifact.py apk APK PACKAGE                           fails unless the APK is this app

Run with python3 -I, so that nothing next to the files it reads is ever imported.
"""

import json
import os
import plistlib
import re
import struct
import sys
import zipfile

REPO = "mmzlopasa/mediarr-dev"
# A release tag of the app, such as app-v1.4.0 or app-v1.4.0-rc1.
STABLE_TAG = re.compile(r"app-v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?")
# Larger than any build so far by far; a bigger file is not one of ours.
MAX_ARTIFACT_BYTES = 1024 * 1024 * 1024


def fail(message):
    sys.exit(message)


def pick_run(channel, workflow, runs):
    """Only a build of this repository's own workflow, started by a push or by hand. A pull request
    from a fork runs its own copy of the workflow under the same path, with any branch name."""

    def wanted(run):
        if run.get("path") != ".github/workflows/" + workflow:
            return False
        if (run.get("repository") or {}).get("full_name") != REPO:
            return False
        if (run.get("head_repository") or {}).get("full_name") != REPO:
            return False
        if run.get("event") not in ("push", "workflow_dispatch"):
            return False
        branch = run.get("head_branch") or ""
        if channel == "stable":
            # Stable comes only from a tag that passed everything.
            return STABLE_TAG.fullmatch(branch) is not None and run.get("conclusion") == "success"
        # Dev is the newest build of main, even if a test failed.
        return branch == "main" and run.get("conclusion") in ("success", "failure")

    found = [run for run in runs.get("workflow_runs", []) if wanted(run)]
    return str(found[0]["id"]) if found else ""


def pick_artifact(name, artifacts):
    for artifact in artifacts.get("artifacts", []):
        if artifact.get("name") != name or artifact.get("expired"):
            continue
        if int(artifact.get("size_in_bytes") or 0) > MAX_ARTIFACT_BYTES:
            fail("the artifact %s is too large" % name)
        url = artifact.get("archive_download_url") or ""
        if not url.startswith("https://api.github.com/repos/%s/actions/artifacts/" % REPO):
            fail("unexpected download address for %s" % name)
        return url
    return ""


def extract(path, member, dest, max_bytes):
    """Writes only the one file asked for, under the name given here, and stops at the limit, so
    neither a name in the zip nor its stated size can lead anywhere else."""
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        if names.count(member) != 1:
            fail("the zip does not hold exactly one %s" % member)
        info = archive.getinfo(member)
        if info.file_size > max_bytes:
            fail("%s is too large" % member)
        written = 0
        with archive.open(info) as source, open(dest, "xb") as out:
            while True:
                chunk = source.read(1024 * 1024)
                if not chunk:
                    break
                written += len(chunk)
                if written > max_bytes:
                    out.close()
                    os.unlink(dest)
                    fail("%s is larger than it says" % member)
                out.write(chunk)


def check_zip(archive):
    bad = archive.testzip()
    if bad is not None:
        fail("damaged file in the archive: %s" % bad)


def ipa(path, bundle_id):
    with zipfile.ZipFile(path) as archive:
        check_zip(archive)
        names = set(archive.namelist())
        main = "Payload/Runner.app/Info.plist"
        if main not in names:
            fail("not an app: %s is missing" % main)
        info = plistlib.loads(archive.read(main))
        if info.get("CFBundleIdentifier") != bundle_id:
            fail("unexpected bundle id: %s" % info.get("CFBundleIdentifier"))
        widget = "Payload/Runner.app/PlugIns/MediarrWidget.appex/Info.plist"
        if widget in names:
            found = plistlib.loads(archive.read(widget)).get("CFBundleIdentifier")
            if found != bundle_id + ".widget":
                fail("unexpected widget bundle id: %s" % found)
        return "%s (%s)" % (info.get("CFBundleShortVersionString"), info.get("CFBundleVersion"))


def manifest_package(data):
    """The package attribute of a compiled AndroidManifest.xml (Android's binary XML)."""
    if len(data) < 8 or struct.unpack_from("<HHI", data, 0)[0] != 0x0003:
        fail("AndroidManifest.xml is not binary XML")
    strings = []
    offset = struct.unpack_from("<H", data, 2)[0]
    while offset + 8 <= len(data):
        kind, header, size = struct.unpack_from("<HHI", data, offset)
        if size < 8 or offset + size > len(data):
            fail("damaged AndroidManifest.xml")
        if kind == 0x0001:  # the string pool
            count, _, flags, start, _ = struct.unpack_from("<IIIII", data, offset + 8)
            utf8 = flags & 0x100
            for i in range(count):
                at = offset + start + struct.unpack_from("<I", data, offset + header + 4 * i)[0]
                if utf8:
                    at += 2 if data[at] & 0x80 else 1  # length in characters
                    length = data[at]
                    if length & 0x80:
                        length = ((length & 0x7F) << 8) | data[at + 1]
                        at += 1
                    strings.append(data[at + 1 : at + 1 + length].decode("utf-8", "replace"))
                else:
                    length = struct.unpack_from("<H", data, at)[0]
                    if length & 0x8000:
                        length = ((length & 0x7FFF) << 16) | struct.unpack_from("<H", data, at + 2)[0]
                        at += 2
                    strings.append(data[at + 2 : at + 2 + 2 * length].decode("utf-16-le", "replace"))
        elif kind == 0x0102:  # the first element, which is <manifest>
            name = struct.unpack_from("<I", data, offset + 20)[0]
            if name >= len(strings) or strings[name] != "manifest":
                fail("AndroidManifest.xml does not start with <manifest>")
            start, attr_size, count = struct.unpack_from("<HHH", data, offset + 24)
            for i in range(count):
                at = offset + 16 + start + i * attr_size
                ns, attr, raw = struct.unpack_from("<III", data, at)
                if ns == 0xFFFFFFFF and attr < len(strings) and strings[attr] == "package":
                    return strings[raw] if raw < len(strings) else ""
            return ""
        offset += size
    return ""


def apk(path, package):
    with zipfile.ZipFile(path) as archive:
        check_zip(archive)
        if "AndroidManifest.xml" not in archive.namelist():
            fail("not an APK: AndroidManifest.xml is missing")
        found = manifest_package(archive.read("AndroidManifest.xml"))
    if found != package:
        fail("unexpected package name: %s" % found)


def main(args):
    if args[:1] == ["run"] and len(args) == 3:
        print(pick_run(args[1], args[2], json.load(sys.stdin)))
    elif args[:1] == ["artifact"] and len(args) == 2:
        print(pick_artifact(args[1], json.load(sys.stdin)))
    elif args[:1] == ["extract"] and len(args) == 5:
        extract(args[1], args[2], args[3], int(args[4]))
    elif args[:1] == ["ipa"] and len(args) == 3:
        print(ipa(args[1], args[2]))
    elif args[:1] == ["apk"] and len(args) == 3:
        apk(args[1], args[2])
    else:
        fail(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
