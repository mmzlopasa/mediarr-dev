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
            "active1d": sum(v["users"] for v in active(1)),
            "active7d": sum(v["users"] for v in week),
            "active30d": sum(v["users"] for v in active(30)),
        },
        "versions": dict(sorted(versions.items())),
        "downloads": {"last30d": month, "total": total},
    }


def remember_day(state, numbers):
    """Keeps one row per day of how many installations and people were active, for the graph."""
    day = numbers["updatedAt"][:10]
    history = state.setdefault("history", {})
    history[day] = {"installs": numbers["installs"]["active1d"], "users": numbers["users"]["active1d"]}
    for old in sorted(history)[:-400]:
        del history[old]


def run_once():
    state = load_state()
    if "secret" not in state:
        state["secret"] = secrets.token_urlsafe(24)
    for line in read_new_lines(state):
        take(state, line)
    numbers = summary(state, datetime.now(UTC))
    remember_day(state, numbers)
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    save(STATE, state)
    base = os.path.join(OUT_DIR, f"stats-{state['secret']}")
    save(base + ".json", numbers)
    os.chmod(base + ".json", 0o644)
    write_page(base + ".html", numbers, state)
    os.chmod(base + ".html", 0o644)
    return base + ".json"


NAMES = {
    "compose": "docker-compose.yml",
    "apk": "Android",
    "apkDev": "Android Dev",
    "ipa": "iPhone",
    "ipaDev": "iPhone Dev",
}


def line_chart(rows, keys, colors, width=480, height=200):
    """An SVG line chart of daily numbers; rows are (day, {key: n})."""
    if not rows:
        return '<p class="empty">No days counted yet.</p>'
    top = max(1, max(r[1].get(k, 0) for r in rows for k in keys))
    pad = 30
    step = (width - 2 * pad) / max(1, len(rows) - 1)

    def point(i, v):
        # A single day sits in the middle rather than against the left edge.
        x = width / 2 if len(rows) == 1 else pad + i * step
        return f"{x:.1f},{height - pad - v / top * (height - 2 * pad):.1f}"

    parts = [f'<svg viewBox="0 0 {width} {height}" role="img" aria-label="Daily numbers">']
    # Whole numbers only: a middle line only when it falls on one.
    for frac in (0, 0.5, 1) if top % 2 == 0 else (0, 1):
        y = height - pad - frac * (height - 2 * pad)
        parts.append(f'<line x1="{pad}" x2="{width - pad}" y1="{y:.1f}" y2="{y:.1f}" class="grid"/>')
        parts.append(f'<text x="4" y="{y + 4:.1f}" class="axis">{round(top * frac)}</text>')
    for key, color in zip(keys, colors, strict=True):
        pts = " ".join(point(i, r[1].get(key, 0)) for i, r in enumerate(rows))
        parts.append(f'<polyline points="{pts}" fill="none" stroke="{color}" stroke-width="2.5"/>')
        for i, r in enumerate(rows):
            parts.append(f'<circle cx="{point(i, r[1].get(key, 0)).split(",")[0]}" '
                         f'cy="{point(i, r[1].get(key, 0)).split(",")[1]}" r="2.5" fill="{color}"/>')
    parts.append(f'<text x="{pad}" y="{height - 6}" class="axis">{rows[0][0]}</text>')
    parts.append(f'<text x="{width - pad}" y="{height - 6}" class="axis" text-anchor="end">{rows[-1][0]}</text>')
    parts.append("</svg>")
    return "".join(parts)


def bar_chart(rows, width=480, height=180):
    """An SVG bar chart of daily totals; rows are (day, total)."""
    if not rows:
        return '<p class="empty">No downloads counted yet.</p>'
    top = max(1, max(n for _, n in rows))
    pad = 28
    slot = (width - 2 * pad) / len(rows)
    parts = [f'<svg viewBox="0 0 {width} {height}" role="img" aria-label="Downloads per day">']
    parts.append(f'<text x="4" y="{pad + 4}" class="axis">{top}</text>')
    for i, (day, n) in enumerate(rows):
        h = n / top * (height - 2 * pad)
        x = pad + i * slot + slot * 0.15
        parts.append(f'<rect x="{x:.1f}" y="{height - pad - h:.1f}" width="{slot * 0.7:.1f}" height="{h:.1f}" '
                     f'rx="2" class="bar"><title>{day}: {n}</title></rect>')
    parts.append(f'<text x="{pad}" y="{height - 6}" class="axis">{rows[0][0]}</text>')
    parts.append(f'<text x="{width - pad}" y="{height - 6}" class="axis" text-anchor="end">{rows[-1][0]}</text>')
    parts.append("</svg>")
    return "".join(parts)


def write_page(path, numbers, state):
    inst, users, dl = numbers["installs"], numbers["users"], numbers["downloads"]
    history = state.get("history", {})
    days = sorted(history)[-90:]
    line_rows = [(d, history[d]) for d in days]
    since = (datetime.now(UTC) - timedelta(days=29)).date()
    daily = state.get("downloads", {})
    bar_rows = []
    for i in range(30):
        d = (since + timedelta(days=i)).isoformat()
        bar_rows.append((d, sum(daily.get(d, {}).values())))
    month = dl.get("last30d", {})
    total = dl.get("total", {})
    rows = "".join(
        f"<tr><td>{NAMES[k]}</td><td>{month.get(k, 0)}</td><td>{total.get(k, 0)}</td></tr>" for k in NAMES
    )
    versions = "".join(f"<tr><td>{v}</td><td>{n}</td></tr>" for v, n in numbers["versions"].items()) or (
        '<tr><td colspan="2" class="empty">No installation has reported yet.</td></tr>'
    )
    updated = numbers["updatedAt"].replace("T", " ").replace("+00:00", " UTC")
    page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex,nofollow"><meta http-equiv="refresh" content="600">
<title>Mediarr: installations</title>
<style>
:root{{color-scheme:dark;--bg:#0d0f14;--card:#151821;--line:#262b38;--ink:#eceae4;--dim:#9a9890;--gold:#ffc83d;--blue:#5aa9ff}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--ink);font:15px/1.45 system-ui,-apple-system,"Segoe UI",sans-serif}}
main{{max-width:820px;margin:0 auto;padding:28px 18px 48px}}h1{{font-size:22px;margin:0 0 4px}}h2{{font-size:15px;margin:28px 0 10px;color:var(--dim);font-weight:600}}
.sub{{color:var(--dim);margin:0 0 22px}}.cards{{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:12px}}
.card{{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:16px}}.n{{font-size:34px;font-weight:700;font-variant-numeric:tabular-nums}}
.card .l{{color:var(--dim);font-size:13px}}.card .s{{color:var(--dim);font-size:12px;margin-top:6px}}
.panel{{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:14px}}svg{{width:100%;height:auto;display:block}}
.grid{{stroke:var(--line)}}.axis{{fill:var(--dim);font-size:13px}}.bar{{fill:var(--gold)}}.key{{display:flex;gap:16px;font-size:13px;color:var(--dim);margin:0 0 8px}}
.key i{{display:inline-block;width:10px;height:10px;border-radius:3px;margin-right:6px;vertical-align:-1px}}
table{{width:100%;border-collapse:collapse;font-variant-numeric:tabular-nums}}td,th{{padding:8px 6px;border-bottom:1px solid var(--line);text-align:left}}
th{{color:var(--dim);font-weight:600;font-size:13px}}td+td,th+th{{text-align:right}}.empty{{color:var(--dim)}}footer{{color:var(--dim);font-size:12px;margin-top:28px}}
</style></head><body><main>
<h1>Mediarr installations</h1><p class="sub">Updated {updated}. The page refreshes itself every 10 minutes.</p>
<div class="cards">
<div class="card"><div class="n">{inst["active7d"]}</div><div class="l">installations, last 7 days</div><div class="s">{inst["active1d"]} today · {inst["active30d"]} in 30 days · {inst["everSeen"]} ever</div></div>
<div class="card"><div class="n">{users["active7d"]}</div><div class="l">people, last 7 days</div><div class="s">{users.get("active1d", 0)} today · {users["active30d"]} in 30 days</div></div>
<div class="card"><div class="n">{sum(month.values())}</div><div class="l">downloads, last 30 days</div><div class="s">{month.get("compose", 0)} installs started · {month.get("apk", 0) + month.get("ipa", 0) + month.get("apkDev", 0) + month.get("ipaDev", 0)} apps</div></div>
</div>
<h2>Installations and people per day</h2><div class="panel"><div class="key"><span><i style="background:var(--gold)"></i>Installations</span><span><i style="background:var(--blue)"></i>People</span></div>
{line_chart(line_rows, ["installs", "users"], ["#ffc83d", "#5aa9ff"])}{'<p class="empty">The graph fills in one day at a time.</p>' if len(line_rows) < 2 else ''}</div>
<h2>Downloads per day, last 30 days</h2><div class="panel">{bar_chart(bar_rows)}</div>
<h2>Downloads</h2><div class="panel"><table><tr><th>File</th><th>30 days</th><th>Total</th></tr>{rows}</table></div>
<h2>Versions in use, last 7 days</h2><div class="panel"><table><tr><th>Version</th><th>Installations</th></tr>{versions}</table></div>
<footer>Installations are counted from the version check each Mediarr server sends every 6 hours: a random number for the installation, its version and how many accounts it has. Downloads are counted once per address and day. No address is kept.</footer>
</main></body></html>
"""
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write(page)
    os.replace(tmp, path)


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
