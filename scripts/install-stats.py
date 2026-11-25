#!/usr/bin/env python3
"""Counts Mediarr installations and downloads from the web server's log, for the owner's dashboard.

Each installation asks cdn.mediarr.app/install/cli/latest.json every 6 hours whether a newer version
exists, with a random number of its own (i), its version (v) and how many accounts it has (u). This
reads those requests, and the downloads of the install files and the apps, from the access log, and
writes the totals to a JSON file with a secret name next to latest.json. It keeps no address: only
the random numbers, the last version and count each one sent, and how many downloads there were.

Runs in its own container (docker/docker-compose.stats.yml), every 10 minutes.
"""

import gzip
import hashlib
import json
import os
import re
import secrets
import sys
import time
from datetime import UTC, datetime, timedelta
from urllib.parse import parse_qs, urlsplit

LOG = os.environ.get("STATS_LOG", "/logs/access.log")
STATE = os.environ.get("STATS_STATE", "/state/state.json")
OUT_DIR = os.environ.get("STATS_OUT", "/out")
EVERY = int(os.environ.get("STATS_EVERY_SECONDS", "600"))

LINE = re.compile(
    r'^(?P<ip>\S+) \S+ \S+ \[(?P<time>[^\]]+)\] "(?P<method>[A-Z]+) (?P<path>\S+) [^"]*" '
    r'(?P<status>\d{3}) (?P<bytes>\d+|-) "[^"]*" "(?P<agent>[^"]*)"'
)
UUID = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")
VERSION = re.compile(r"^(v\d+\.\d+\.\d+(-[0-9A-Za-z.]+)?|dev)$")
DOWNLOADS = {
    "/install/docker-compose.yml": "compose",
    "/apps/mediarr.apk": "apk",
    "/apps/mediarr.ipa": "ipa",
    "/apps/mediarr-dev.apk": "apkDev",
    "/apps/mediarr-dev.ipa": "ipaDev",
}
# A download is counted once per address and day; the address is only hashed, with a salt that
# changes every day and is never written down, so the hashes cannot be turned back into addresses.
DAILY_SALT = {}


def load_state():
    try:
        with open(STATE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save(path, data):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, separators=(",", ":"), sort_keys=True)
    os.replace(tmp, path)


def when(text):
    return datetime.strptime(text, "%d/%b/%Y:%H:%M:%S %z").astimezone(UTC)


def seen_today(state, day, key):
    salt = DAILY_SALT.setdefault(day, secrets.token_bytes(16))
    digest = hashlib.sha256(salt + key.encode()).hexdigest()[:16]
    today = state.setdefault("today", {})
    if today.get("day") != day:
        today.clear()
        today["day"] = day
        today["seen"] = []
    if digest in today["seen"]:
        return True
    today["seen"].append(digest)
    return False


def read_new_lines(state):
    """The lines added since the last run. A new or shorter file starts from its beginning."""
    try:
        info = os.stat(LOG)
    except OSError as e:
        print(f"cannot read the log: {e}", file=sys.stderr)
        return
    pos = state.get("log", {})
    offset = pos.get("offset", 0) if pos.get("inode") == info.st_ino and pos.get("offset", 0) <= info.st_size else 0
    opener = gzip.open if LOG.endswith(".gz") else open
    with opener(LOG, "rb") as f:
        f.seek(offset)
        for raw in f:
            if not raw.endswith(b"\n"):
                break
            offset += len(raw)
            yield raw.decode("utf-8", "replace")
    state["log"] = {"inode": info.st_ino, "offset": offset}


def take(state, line):
    m = LINE.match(line)
    if not m or m["method"] not in ("GET", "HEAD"):
        return
    url = urlsplit(m["path"])
    at = when(m["time"])
    if url.path == "/install/cli/latest.json" and m["agent"].startswith("Mediarr/"):
        q = parse_qs(url.query)
        install = (q.get("i") or [""])[0].lower()
        version = (q.get("v") or [""])[0]
        users = (q.get("u") or [""])[0]
        if not UUID.match(install) or not VERSION.match(version) or not users.isdigit():
            return
        installs = state.setdefault("installs", {})
        known = installs.setdefault(install, {"first": at.isoformat()})
        known.update(last=at.isoformat(), version=version, users=min(int(users), 1_000_000))
        return
    name = DOWNLOADS.get(url.path)
    if name and m["method"] == "GET" and m["status"] in ("200", "206"):
        day = at.date().isoformat()
        if seen_today(state, day, m["ip"] + name):
            return
        days = state.setdefault("downloads", {})
        days.setdefault(day, {}).setdefault(name, 0)
        days[day][name] += 1


def summary(state, now):
    installs = state.get("installs", {})

    def active(days):
        since = now - timedelta(days=days)
        return [v for v in installs.values() if datetime.fromisoformat(v["last"]) >= since]

    week = active(7)
    versions = {}
    for v in week:
        versions[v["version"]] = versions.get(v["version"], 0) + 1
    downloads = state.get("downloads", {})
    month_start = (now - timedelta(days=30)).date().isoformat()
    total, month = {}, {}
    for day, counts in downloads.items():
        for name, n in counts.items():
            total[name] = total.get(name, 0) + n
            if day >= month_start:
                month[name] = month.get(name, 0) + n
    return {
        "updatedAt": now.replace(microsecond=0).isoformat(),
        "installs": {
            "active1d": len(active(1)),
            "active7d": len(week),
            "active30d": len(active(30)),
            "everSeen": len(installs),
        },
        "users": {
            "active7d": sum(v["users"] for v in week),
            "active30d": sum(v["users"] for v in active(30)),
        },
        "versions": dict(sorted(versions.items())),
        "downloads": {"last30d": month, "total": total},
    }


def run_once():
    state = load_state()
    if "secret" not in state:
        state["secret"] = secrets.token_urlsafe(24)
    for line in read_new_lines(state):
        take(state, line)
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    save(STATE, state)
    out = os.path.join(OUT_DIR, f"stats-{state['secret']}.json")
    save(out, summary(state, datetime.now(UTC)))
    os.chmod(out, 0o644)
    return out


if __name__ == "__main__":
    if "--once" in sys.argv:
        print(run_once())
        sys.exit(0)
    while True:
        try:
            run_once()
        except Exception as e:  # One bad run must not stop the counting.
            print(f"stats run failed: {e}", file=sys.stderr)
        time.sleep(EVERY)
