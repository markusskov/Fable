#!/usr/bin/env python3
"""Minimal App Store Connect API client for Fable metadata pushes.

Auth: AuthKey .p8 in ~/Documents/ASC, key ID from the filename, issuer ID
from ~/Documents/ASC/issuer.txt (one UUID, written by the owner).
"""
import json, re, sys, time, urllib.request, pathlib

import jwt

ASC_DIR = pathlib.Path.home() / "Documents" / "ASC"
BASE = "https://api.appstoreconnect.apple.com"

def token():
    key_file = next(ASC_DIR.glob("AuthKey_*.p8"))
    key_id = key_file.stem.split("_")[1]
    issuer = (ASC_DIR / "issuer.txt").read_text().strip()
    now = int(time.time())
    return jwt.encode(
        {"iss": issuer, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"},
        key_file.read_text(),
        algorithm="ES256",
        headers={"kid": key_id},
    )

def call(method, path, payload=None):
    req = urllib.request.Request(
        BASE + path,
        method=method,
        headers={
            "Authorization": f"Bearer {token()}",
            "Content-Type": "application/json",
        },
        data=json.dumps(payload).encode() if payload is not None else None,
    )
    try:
        with urllib.request.urlopen(req) as response:
            body = response.read()
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as error:
        detail = error.read().decode()
        raise SystemExit(f"{method} {path} -> {error.code}\n{detail}")

# ---- pack parsing -----------------------------------------------------------

PACKS = {
    "en-US": "docs/appstore/metadata.md",
    "de-DE": "docs/appstore/metadata-de.md",
    "nb": "docs/appstore/metadata-nb.md",
    "es-ES": "docs/appstore/metadata-es.md",
    "fr-FR": "docs/appstore/metadata-fr.md",
    "it": "docs/appstore/metadata-it.md",
    "pt-BR": "docs/appstore/metadata-pt-BR.md",
}
WHATS_NEW_KEYS = {
    "en-US": "en", "de-DE": "de", "nb": "nb", "es-ES": "es",
    "fr-FR": "fr", "it": "it", "pt-BR": "pt-BR",
}

def section(text, heading):
    match = re.search(rf"^## {re.escape(heading)}.*?$(.*?)(?=^## |\Z)",
                      text, re.M | re.S)
    return match.group(1).strip() if match else None

# The "(168)" or "(94 bytes)" the pack author appended after a block —
# annotation for humans, never part of the upload (same rule as
# scripts/check-store-metadata.py).
TRAILING_COUNT = re.compile(r"\s*\(\d+(?:\s+\w+)?\)\s*$")

def blockquote(chunk):
    lines = []
    for line in chunk.splitlines():
        if line.startswith(">"):
            lines.append(line[2:] if line.startswith("> ") else line[1:])
    return TRAILING_COUNT.sub("", "\n".join(lines).strip()).strip()

def backticked(chunk, label):
    match = re.search(rf"\*\*{re.escape(label)}[^:]*:\*\* `([^`]*)`", chunk)
    return match.group(1) if match else None

DESC_HEADINGS = ("description", "beskrivelse", "descrizione", "descri")
KEYWORD_HEADINGS = ("keyword", "parole chiave", "palavras", "mots-cl", "nøkkelord")
PROMO_HEADINGS = ("promo", "kampanjetekst")
SUBTITLE_LABEL = re.compile(
    r"\*\*(?:Subtitle|Sous-titre|Sottotitolo|Undertittel|Subt\u00edtulo)"
    r"[^*]*\*\*\s*`([^`]+)`")

def sections(text):
    out = {}
    for match in re.finditer(r"^## (.+?)$(.*?)(?=^## |\Z)", text, re.M | re.S):
        out[match.group(1).strip().lower()] = match.group(2)
    return out

def find_section(secs, needles):
    for heading, body in secs.items():
        if any(needle in heading for needle in needles):
            return body
    return None

def parse_pack(path):
    text = pathlib.Path(path).read_text()
    secs = sections(text)
    subtitle_match = SUBTITLE_LABEL.search(text)
    keywords_body = find_section(secs, KEYWORD_HEADINGS) or ""
    keyword_match = re.search(r"`([^`]+)`", keywords_body)
    return {
        "subtitle": subtitle_match.group(1) if subtitle_match else None,
        "description": blockquote(find_section(secs, DESC_HEADINGS) or ""),
        "keywords": keyword_match.group(1) if keyword_match else None,
        "promotionalText": blockquote(find_section(secs, PROMO_HEADINGS) or "") or None,
    }

def parse_whats_new():
    text = pathlib.Path("docs/appstore/whats-new-1.1.md").read_text()
    notes = {}
    for match in re.finditer(r"^## (\S+)$(.*?)(?=^## |\Z)", text, re.M | re.S):
        notes[match.group(1)] = blockquote(match.group(2))
    return notes


APP_ID = "6793714797"
SUPPORT_URL = "https://markusskov.github.io/Fable/"
PRIVACY_URL = "https://markusskov.github.io/Fable/privacy"
NEW_OR_MANAGED_INFO_LOCALES = ["es-ES", "fr-FR", "it", "pt-BR"]
ASC_TO_PACK = {"no": "nb", "de-DE": "de-DE", "en-US": "en-US",
               "es-ES": "es-ES", "fr-FR": "fr-FR", "it": "it", "pt-BR": "pt-BR"}

def editable_version():
    versions = call("GET", f"/v1/apps/{APP_ID}/appStoreVersions?limit=5")
    for version in versions["data"]:
        if version["attributes"]["appStoreState"] in (
                "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED"):
            return version["id"], version["attributes"]["versionString"]
    raise SystemExit("no editable app store version found")

def editable_app_info():
    infos = call("GET", f"/v1/apps/{APP_ID}/appInfos?limit=5")
    for info in infos["data"]:
        state = info["attributes"].get("appStoreState") or info["attributes"].get("state")
        if state == "PREPARE_FOR_SUBMISSION":
            return info["id"]
    raise SystemExit("no editable app info found")

def inspect():
    versions = call("GET", f"/v1/apps/{APP_ID}/appStoreVersions?limit=5")
    for version in versions["data"]:
        attrs = version["attributes"]
        print(f"version {attrs['versionString']} [{attrs['appStoreState']}] id={version['id']}")
        if attrs["appStoreState"] in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED"):
            locs = call("GET", f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations?limit=20")
            for loc in locs["data"]:
                a = loc["attributes"]
                print(f"  verLoc {a['locale']} id={loc['id']} "
                      f"desc={len(a.get('description') or '')}ch "
                      f"whatsNew={len(a.get('whatsNew') or '')}ch")
    infos = call("GET", f"/v1/apps/{APP_ID}/appInfos?limit=5")
    for info in infos["data"]:
        state = info["attributes"].get("appStoreState") or info["attributes"].get("state")
        print(f"appInfo id={info['id']} state={state}")
        locs = call("GET", f"/v1/appInfos/{info['id']}/appInfoLocalizations?limit=20")
        for loc in locs["data"]:
            a = loc["attributes"]
            print(f"  infoLoc {a['locale']} id={loc['id']} name={a.get('name')!r} subtitle={a.get('subtitle')!r}")


def push():
    version_id, version_string = editable_version()
    app_info_id = editable_app_info()
    print(f"syncing listings into draft version {version_string}")
    notes = parse_whats_new()
    all_locales = list(ASC_TO_PACK)

    existing_ver = {
        loc["attributes"]["locale"]: loc["id"]
        for loc in call("GET", f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=20")["data"]
    }
    for locale in all_locales:
        pack = parse_pack(PACKS[ASC_TO_PACK[locale]])
        attrs = {
            "description": pack["description"],
            "keywords": pack["keywords"],
            "promotionalText": pack["promotionalText"],
            "whatsNew": notes[WHATS_NEW_KEYS[ASC_TO_PACK[locale]]],
        }
        if locale in existing_ver:
            call("PATCH", f"/v1/appStoreVersionLocalizations/{existing_ver[locale]}", {"data": {
                "type": "appStoreVersionLocalizations",
                "id": existing_ver[locale],
                "attributes": attrs,
            }})
            print(f"verLoc {locale}: patched")
        else:
            attrs.update({"locale": locale, "supportUrl": SUPPORT_URL})
            call("POST", "/v1/appStoreVersionLocalizations", {"data": {
                "type": "appStoreVersionLocalizations",
                "attributes": attrs,
                "relationships": {"appStoreVersion": {"data": {
                    "type": "appStoreVersions", "id": version_id}}},
            }})
            print(f"verLoc {locale}: created")

    info_locs = {
        loc["attributes"]["locale"]: loc["id"]
        for loc in call("GET", f"/v1/appInfos/{app_info_id}/appInfoLocalizations?limit=20")["data"]
    }
    # Only the NEW locales get info fields written; the three live ones keep
    # the owner's hand-set name/subtitle untouched.
    for locale in NEW_OR_MANAGED_INFO_LOCALES:
        pack = parse_pack(PACKS[ASC_TO_PACK[locale]])
        attrs = {
            "name": "Fable Bedtime",
            "subtitle": pack["subtitle"],
            "privacyPolicyUrl": PRIVACY_URL,
        }
        if locale in info_locs:
            call("PATCH", f"/v1/appInfoLocalizations/{info_locs[locale]}", {"data": {
                "type": "appInfoLocalizations",
                "id": info_locs[locale],
                "attributes": attrs,
            }})
            print(f"infoLoc {locale}: patched subtitle={pack['subtitle']!r}")
        else:
            attrs["locale"] = locale
            call("POST", "/v1/appInfoLocalizations", {"data": {
                "type": "appInfoLocalizations",
                "attributes": attrs,
                "relationships": {"appInfo": {"data": {
                    "type": "appInfos", "id": app_info_id}}},
            }})
            print(f"infoLoc {locale}: created subtitle={pack['subtitle']!r}")



if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else "help"
    if command == "whoami":
        apps = call("GET", "/v1/apps?filter[bundleId]=com.markusskov.fable")
        for app in apps["data"]:
            print(app["id"], app["attributes"]["name"], app["attributes"]["bundleId"])
    elif command == "inspect":
        inspect()
    elif command == "parse":
        for locale, path in PACKS.items():
            fields = parse_pack(path)
            print(f"{locale}: subtitle={fields['subtitle']!r} desc={len(fields['description'])}ch "
                  f"kw={len(fields['keywords'] or '')}ch promo={len(fields['promotionalText'] or '')}ch")
    elif command == "push":
        push()
    else:
        print(__doc__)
        print("commands: whoami | inspect | parse | push")
