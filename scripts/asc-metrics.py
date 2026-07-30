#!/usr/bin/env python3
"""ASC metrics loop (Milestone 7): the funnel, from the API into the repo.

Two data systems, used for what each is good at:
- SALES reports (daily gzipped TSV): units and proceeds per country, fast
  and simple. `sales` prints a per-storefront day summary.
- ANALYTICS reports (async report system): impressions, product page
  views, conversion — richer but must be REQUESTED once (ONGOING) and
  then accumulates. `analytics-setup` creates that standing request;
  `analytics-list` shows what is ready to read.

Auth: the same App Manager key as asc-sync-listings (~/Documents/ASC).

Usage, from the repo root:
  scripts/asc-metrics.py sales [YYYY-MM-DD]     # default: yesterday
  scripts/asc-metrics.py analytics-setup        # once; standing request
  scripts/asc-metrics.py analytics-list
"""
import csv, datetime, gzip, io, json, pathlib, sys, time, urllib.request

import jwt

ASC_DIR = pathlib.Path.home() / "Documents" / "ASC"
BASE = "https://api.appstoreconnect.apple.com"
APP_ID = "6793714797"
VENDOR_FILE = ASC_DIR / "vendor.txt"  # vendor number, from ASC Payments page

def token():
    key_file = next(ASC_DIR.glob("AuthKey_*.p8"))
    issuer = (ASC_DIR / "issuer.txt").read_text().strip()
    now = int(time.time())
    return jwt.encode(
        {"iss": issuer, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"},
        key_file.read_text(), algorithm="ES256",
        headers={"kid": key_file.stem.split("_")[1]})

def call(method, path, payload=None, raw=False):
    req = urllib.request.Request(
        BASE + path, method=method,
        headers={"Authorization": f"Bearer {token()}",
                 "Content-Type": "application/json",
                 "Accept": "application/a-gzip" if raw else "application/json"},
        data=json.dumps(payload).encode() if payload else None)
    try:
        with urllib.request.urlopen(req) as response:
            body = response.read()
            if raw:
                return body
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as error:
        raise SystemExit(f"{method} {path} -> {error.code}\n{error.read().decode()[:400]}")

def sales(day):
    if not VENDOR_FILE.exists():
        raise SystemExit(f"no vendor number at {VENDOR_FILE} — ASC → Payments "
                         "and Financial Reports shows it (8-digit number); "
                         "one line in that file")
    vendor = "".join(ch for ch in VENDOR_FILE.read_text() if ch.isdigit())
    path = ("/v1/salesReports?filter[frequency]=DAILY"
            f"&filter[reportDate]={day}"
            "&filter[reportSubType]=SUMMARY&filter[reportType]=SALES"
            f"&filter[vendorNumber]={vendor}")
    body = call("GET", path, raw=True)
    text = gzip.decompress(body).decode("utf-8", errors="replace")
    rows = list(csv.DictReader(io.StringIO(text), delimiter="\t"))
    ours = [r for r in rows if r.get("Apple Identifier") == APP_ID]
    by_country = {}
    proceeds = 0.0
    for row in ours:
        units = int(row.get("Units", 0))
        country = row.get("Country Code", "?")
        kind = row.get("Product Type Identifier", "")
        # 1/1F/1T etc = app download; IA*/renewals = purchases
        bucket = "downloads" if kind.startswith("1") else "purchases"
        by_country.setdefault(country, {"downloads": 0, "purchases": 0})
        by_country[country][bucket] += units
        proceeds += float(row.get("Developer Proceeds", 0) or 0) * units
    print(f"{day} — {len(ours)} sales rows")
    for country, counts in sorted(by_country.items()):
        print(f"  {country}: {counts['downloads']} downloads, {counts['purchases']} purchases")
    print(f"  proceeds: ~${proceeds:.2f} (mixed currencies, unconverted)")
    if not ours:
        print("  (no rows for the app; a quiet day or the report is not ready yet)")

def analytics_setup():
    existing = call("GET", f"/v1/apps/{APP_ID}/analyticsReportRequests")
    for request in existing.get("data", []):
        if request["attributes"].get("accessType") == "ONGOING":
            print(f"standing request already exists: {request['id']}")
            return
    created = call("POST", "/v1/analyticsReportRequests", {"data": {
        "type": "analyticsReportRequests",
        "attributes": {"accessType": "ONGOING"},
        "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
    }})
    print(f"created standing analytics request: {created['data']['id']}")
    print("reports populate over the coming days; check analytics-list")

def analytics_list():
    requests = call("GET", f"/v1/apps/{APP_ID}/analyticsReportRequests")
    for request in requests.get("data", []):
        print(f"request {request['id']} [{request['attributes'].get('accessType')}]")
        reports = call("GET", f"/v1/analyticsReportRequests/{request['id']}/reports?limit=50")
        for report in reports.get("data", []):
            a = report["attributes"]
            print(f"  {a.get('category')}/{a.get('name')}")

if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else "help"
    if command == "sales":
        day = sys.argv[2] if len(sys.argv) > 2 else str(datetime.date.today() - datetime.timedelta(days=1))
        sales(day)
    elif command == "analytics-setup":
        analytics_setup()
    elif command == "analytics-list":
        analytics_list()
    else:
        print(__doc__)
