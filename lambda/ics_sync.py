"""
ICS Sync Lambda — Meetup calendar change → GitHub repository_dispatch

Fetches the Meetup.com iCal feed for AWS UG Mixtli, compares the next
upcoming event against the last known fingerprint in SSM Parameter Store,
and fires a GitHub repository_dispatch event when anything changes so the
Hugo site rebuilds immediately (title, date, venue reschedule, etc.).

The GitHub Actions workflow also runs on a daily cron as a safety net;
this Lambda handles the immediate "Meetup just changed" trigger.

Triggered every 6 hours via EventBridge Scheduler.

Environment variables:
  GITHUB_REPO       – "org/repo" slug, e.g. "awsugmixtli/web"
  GITHUB_SSM_PARAM  – SSM SecureString parameter name holding the GitHub PAT
                      (needs Actions write or repo scope for repository_dispatch)
  STATE_SSM_PARAM   – SSM String parameter name for last-known event fingerprint

Setup after first terraform apply:
  aws ssm put-parameter \\
      --name /mixtli/github-pat \\
      --value "github_pat_XXXX" \\
      --type SecureString --overwrite --region us-east-1
"""

import json
import os
import re
import urllib.request
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

import boto3

ICAL_URL         = "https://www.meetup.com/awsugmixtli/events/ical"
GITHUB_REPO      = os.environ["GITHUB_REPO"]
GITHUB_SSM_PARAM = os.environ["GITHUB_SSM_PARAM"]
STATE_SSM_PARAM  = os.environ["STATE_SSM_PARAM"]

ssm = boto3.client("ssm")


# ── iCal helpers (RFC 5545) ───────────────────────────────────────────────────

def unfold(text: str) -> str:
    """Remove iCal line continuations (CRLF + whitespace)."""
    return re.sub(r"\r\n[ \t]|\n[ \t]", "", text)


def prop(block: str, name: str) -> str | None:
    """Return the value of an iCal property, stripping any parameters."""
    m = re.search(rf"^{re.escape(name)}(?:;[^:]*)?:(.*)", block, re.MULTILINE)
    return m.group(1).strip() if m else None


def decode_ical(s: str) -> str:
    """Unescape iCal text (RFC 5545 §3.3.11)."""
    return (
        s.replace("\\n", "\n")
         .replace("\\,", ",")
         .replace("\\;", ";")
         .replace("\\\\", "\\")
    )


def parse_ical_date(val: str, tzid: str | None = None) -> datetime:
    """Parse an iCal DTSTART value into a timezone-aware UTC datetime."""
    if ":" in val:
        val = val.split(":")[-1]
    y  = val[0:4]; mo = val[4:6]; d  = val[6:8]
    h  = val[9:11]; mi = val[11:13]; s  = val[13:15] if len(val) > 13 else "00"
    dt = datetime.fromisoformat(f"{y}-{mo}-{d}T{h}:{mi}:{s}")
    if val.endswith("Z"):
        tz = timezone.utc
    elif tzid:
        tz = ZoneInfo(tzid)
    else:
        tz = timezone.utc
    return dt.replace(tzinfo=tz).astimezone(timezone.utc)


# ── GitHub dispatch ───────────────────────────────────────────────────────────

def fire_dispatch(token: str, event_type: str = "meetup-changed") -> None:
    """POST a repository_dispatch event to GitHub Actions."""
    url  = f"https://api.github.com/repos/{GITHUB_REPO}/dispatches"
    body = json.dumps({"event_type": event_type}).encode()
    req  = urllib.request.Request(
        url,
        data=body,
        headers={
            "Authorization":        f"Bearer {token}",
            "Accept":               "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "Content-Type":         "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        # GitHub returns 204 No Content on success
        print(f"GitHub dispatch HTTP {resp.status} — event_type={event_type!r}")


# ── Lambda handler ────────────────────────────────────────────────────────────

def handler(event, context):
    # 1. Fetch iCal feed
    with urllib.request.urlopen(ICAL_URL, timeout=15) as resp:
        raw = unfold(resp.read().decode("utf-8", errors="replace"))

    blocks = re.findall(r"BEGIN:VEVENT([\s\S]*?)END:VEVENT", raw)
    if not blocks:
        raise ValueError("No VEVENT blocks found in iCal feed")

    now = datetime.now(timezone.utc)

    # 2. Collect upcoming events and sort by start date
    upcoming = []
    for block in blocks:
        dtstart_raw = prop(block, "DTSTART")
        if not dtstart_raw:
            continue
        tzid_m = re.search(r"^DTSTART;[^:]*TZID=([^;:]+)", block, re.MULTILINE)
        tzid = tzid_m.group(1) if tzid_m else None
        try:
            start = parse_ical_date(dtstart_raw, tzid)
        except (ValueError, IndexError):
            continue
        if start <= now:
            continue
        upcoming.append({
            "title": decode_ical(prop(block, "SUMMARY") or ""),
            "start": start,
            "uid":   prop(block, "UID") or "",
        })

    if not upcoming:
        print("No upcoming events in iCal feed — nothing to trigger")
        return {"statusCode": 200, "body": "no upcoming events"}

    upcoming.sort(key=lambda e: e["start"])
    next_event = upcoming[0]

    # 3. Build fingerprint from UID + start ISO (catches both new events and reschedules)
    fingerprint = f"{next_event['uid']}|{next_event['start'].isoformat()}"
    print(f"Next event: {next_event['title']!r} @ {next_event['start']} [{fingerprint}]")

    # 4. Compare with last persisted fingerprint
    try:
        last_fingerprint = ssm.get_parameter(Name=STATE_SSM_PARAM)["Parameter"]["Value"]
    except ssm.exceptions.ParameterNotFound:
        last_fingerprint = ""

    if fingerprint == last_fingerprint:
        print("Meetup calendar unchanged — no rebuild needed")
        return {"statusCode": 200, "body": "no change"}

    # 5. Something changed — update state and fire rebuild
    print(f"Change detected: {last_fingerprint!r} → {fingerprint!r}")
    ssm.put_parameter(Name=STATE_SSM_PARAM, Value=fingerprint, Overwrite=True)

    token = ssm.get_parameter(
        Name=GITHUB_SSM_PARAM,
        WithDecryption=True,
    )["Parameter"]["Value"]
    fire_dispatch(token)

    print(f"Rebuild triggered for {GITHUB_REPO} — {next_event['title']!r}")
    return {
        "statusCode": 200,
        "body": json.dumps({"triggered": True, "event": next_event["title"]}),
    }


if __name__ == "__main__":
    print("Running handler locally…")
    handler({}, None)
