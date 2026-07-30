#!/usr/bin/env python3
"""Route A scene generator: Gemini image generation (Nano Banana) painting
the emotional layer for ad creatives, prompts sourced from the SCENE lines
of docs/launch/ad-angles.md.

Auth: API key in ~/Documents/Keys/gemini.txt (owner-provisioned; never in
the repo). UNTESTED until a key exists — written key-ready so provisioning
is the only remaining step.

Usage, from the repo root:
  python3 tools/adfactory/scenegen-gemini.py [out-dir]
"""
import base64, json, pathlib, re, sys, urllib.request

KEY_FILE = pathlib.Path.home() / "Documents" / "Keys" / "gemini.txt"
MODEL = "gemini-2.5-flash-image"
STYLE = ("warm storybook illustration, cozy nighttime blues and deep violet "
         "with golden light, soft and calm, no text, no words")

def scenes():
    text = pathlib.Path("docs/launch/ad-angles.md").read_text()
    found = []
    for match in re.finditer(r"^## \d+\. (.+?)$(.*?)(?=^## |\Z)", text, re.M | re.S):
        body = match.group(2)
        scene = re.search(r"- SCENE: (.+?)(?=\n- [A-Z]|\Z)", body, re.S)
        if scene:
            slug = re.sub(r"[^a-z0-9]+", "-", match.group(1).lower()).strip("-")
            found.append((slug, " ".join(scene.group(1).split())))
    return found

def generate(prompt, key):
    url = (f"https://generativelanguage.googleapis.com/v1beta/models/"
           f"{MODEL}:generateContent?key={key}")
    payload = {"contents": [{"parts": [{"text": f"{prompt} {STYLE}"}]}]}
    req = urllib.request.Request(url, method="POST",
                                 headers={"Content-Type": "application/json"},
                                 data=json.dumps(payload).encode())
    with urllib.request.urlopen(req) as response:
        body = json.load(response)
    for part in body["candidates"][0]["content"]["parts"]:
        data = part.get("inlineData")
        if data and data.get("mimeType", "").startswith("image/"):
            return base64.b64decode(data["data"])
    raise SystemExit(f"no image in response: {json.dumps(body)[:300]}")

def main():
    if not KEY_FILE.exists():
        raise SystemExit(f"no key at {KEY_FILE} — owner provisions (Google AI "
                         "Studio API key, one line in that file)")
    key = KEY_FILE.read_text().strip()
    out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "out/scenes")
    out.mkdir(parents=True, exist_ok=True)
    for slug, prompt in scenes():
        png = generate(prompt, key)
        path = out / f"{slug}.png"
        path.write_bytes(png)
        print(f"{slug} -> {path} ({len(png)//1024} KB)")

if __name__ == "__main__":
    main()
