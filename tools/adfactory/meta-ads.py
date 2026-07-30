#!/usr/bin/env python3
"""Meta Marketing API publisher for the discovery campaign.

Discipline (docs/launch/ad-angles.md + the ban-myth rule): WRITES go
through the Marketing API — create, pause, promote. Reads are modest
Insights calls for the weekly readout, never bulk pulls. Everything is
created PAUSED: the owner reviews in Ads Manager and flips it live —
sessions stage, the owner fires.

Auth (owner-provisioned, never in the repo), one value per line:
  ~/Documents/Keys/meta.txt:
    line 1: long-lived access token (System User token recommended)
    line 2: ad account id (act_XXXXXXXX)
    line 3: Facebook Page id

UNTESTED until those exist — written key-ready so Meta Business setup
is the only remaining step.

Usage, from the repo root:
  python3 tools/adfactory/meta-ads.py plan            # dry-run: what would be created
  python3 tools/adfactory/meta-ads.py publish         # create campaign+adsets+ads, PAUSED
  python3 tools/adfactory/meta-ads.py status          # campaign tree with delivery status
  python3 tools/adfactory/meta-ads.py readout         # per-ad CTR/CPC table for docs/metrics/
  python3 tools/adfactory/meta-ads.py pause <ad-id>   # kill a loser

Manifest: docs/ads/manifest.json — [{"angle": "asleep", "image":
"docs/ads/finals/asleep-feed.png", "primary": "...", "headline": "..."}]
(copy defaults come from ad-angles.md HOOK/SUPPORT when omitted).
"""
import json, pathlib, sys, urllib.parse, urllib.request

KEY_FILE = pathlib.Path.home() / "Documents" / "Keys" / "meta.txt"
GRAPH = "https://graph.facebook.com/v21.0"
APP_STORE_URL = "https://apps.apple.com/app/id6793714797"
CAMPAIGN_NAME = "Fable discovery — Stage 1 angles"
DAILY_BUDGET_CENTS = 2500  # $25/day at the adset level; owner adjusts in Ads Manager
COUNTRIES = ["US", "GB", "CA", "AU"]

def credentials():
    if not KEY_FILE.exists():
        raise SystemExit(f"no credentials at {KEY_FILE} — owner provisions "
                         "(token / act id / page id, one per line)")
    token, account, page = [l.strip() for l in KEY_FILE.read_text().splitlines()[:3]]
    return token, account, page

def call(method, path, token, payload=None):
    data = None
    if payload is not None:
        payload = dict(payload, access_token=token)
        data = urllib.parse.urlencode(payload).encode()
    else:
        path += ("&" if "?" in path else "?") + "access_token=" + token
    req = urllib.request.Request(f"{GRAPH}/{path}", method=method, data=data)
    try:
        with urllib.request.urlopen(req) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        raise SystemExit(f"{method} {path.split('?')[0]} -> {error.code}\n{error.read().decode()[:500]}")

def manifest():
    path = pathlib.Path("docs/ads/manifest.json")
    if not path.exists():
        raise SystemExit("docs/ads/manifest.json missing — owner drops finals "
                         "in docs/ads/finals/ and a session builds the manifest")
    return json.loads(path.read_text())

def plan():
    ads = manifest()
    print(f"campaign: {CAMPAIGN_NAME} (PAUSED)")
    print(f"  adset: broad {'/'.join(COUNTRIES)}, ${DAILY_BUDGET_CENTS/100:.0f}/day, link clicks -> {APP_STORE_URL}")
    for ad in ads:
        print(f"    ad [{ad['angle']}] {ad['image']}")
        print(f"       headline: {ad['headline']}")

def publish():
    token, account, page = credentials()
    ads = manifest()
    campaign = call("POST", f"{account}/campaigns", token, {
        "name": CAMPAIGN_NAME, "objective": "OUTCOME_TRAFFIC",
        "status": "PAUSED", "special_ad_categories": "[]",
    })["id"]
    print(f"campaign {campaign} (paused)")
    adset = call("POST", f"{account}/adsets", token, {
        "name": "Stage 1 — broad English", "campaign_id": campaign,
        "daily_budget": DAILY_BUDGET_CENTS, "billing_event": "IMPRESSIONS",
        "optimization_goal": "LINK_CLICKS", "bid_strategy": "LOWEST_COST_WITHOUT_CAP",
        "status": "PAUSED",
        "targeting": json.dumps({
            "geo_locations": {"countries": COUNTRIES},
            "age_min": 22,
            "publisher_platforms": ["facebook", "instagram"],
        }),
    })["id"]
    print(f"adset {adset} (paused)")
    for ad in ads:
        with open(ad["image"], "rb") as f:
            image_data = f.read()
        boundary = "----fableadfactory"
        body = (f'--{boundary}\r\nContent-Disposition: form-data; name="access_token"\r\n\r\n{token}\r\n'
                f'--{boundary}\r\nContent-Disposition: form-data; name="source"; filename="ad.png"\r\n'
                f'Content-Type: image/png\r\n\r\n').encode() + image_data + f'\r\n--{boundary}--\r\n'.encode()
        req = urllib.request.Request(f"{GRAPH}/{account}/adimages", method="POST", data=body,
                                     headers={"Content-Type": f"multipart/form-data; boundary={boundary}"})
        with urllib.request.urlopen(req) as response:
            uploaded = json.load(response)
        image_hash = next(iter(uploaded["images"].values()))["hash"]
        creative = call("POST", f"{account}/adcreatives", token, {
            "name": f"{ad['angle']} creative",
            "object_story_spec": json.dumps({
                "page_id": page,
                "link_data": {
                    "image_hash": image_hash,
                    "link": APP_STORE_URL,
                    "message": ad["primary"],
                    "name": ad["headline"],
                    "call_to_action": {"type": "DOWNLOAD"},
                },
            }),
        })["id"]
        ad_id = call("POST", f"{account}/ads", token, {
            "name": f"[{ad['angle']}]", "adset_id": adset,
            "creative": json.dumps({"creative_id": creative}), "status": "PAUSED",
        })["id"]
        print(f"ad {ad_id} [{ad['angle']}] (paused)")
    print("\nEverything PAUSED. Owner reviews in Ads Manager and flips live.")

def status():
    token, account, _ = credentials()
    campaigns = call("GET", f"{account}/campaigns?fields=name,status,effective_status", token)
    for c in campaigns.get("data", []):
        print(c["id"], c["status"], c["name"])

def readout():
    token, account, _ = credentials()
    rows = call("GET", f"{account}/insights?level=ad&fields=ad_name,impressions,ctr,cpc,spend&date_preset=last_7d", token)
    print(f"{'ad':28} {'impr':>8} {'ctr%':>6} {'cpc$':>6} {'spend$':>7}")
    for row in rows.get("data", []):
        print(f"{row.get('ad_name',''):28} {row.get('impressions',''):>8} "
              f"{row.get('ctr',''):>6} {row.get('cpc',''):>6} {row.get('spend',''):>7}")

def pause(ad_id):
    token, _, _ = credentials()
    call("POST", ad_id, token, {"status": "PAUSED"})
    print(f"{ad_id} paused")

if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else "plan"
    if command == "plan": plan()
    elif command == "publish": publish()
    elif command == "status": status()
    elif command == "readout": readout()
    elif command == "pause" and len(sys.argv) > 2: pause(sys.argv[2])
    else: print(__doc__)
