#!/usr/bin/env python3
"""Measure App Store metadata against Apple's field limits.

Every localized pack in docs/appstore/ writes its own limit into the
heading ("Promotional text (170 chars max)", "Testo promozionale (max
170)"), and each block carries a hand-written character count. Both have
drifted: the Italian promotional text is annotated (168) and is actually
over. This measures the text itself, so a field that would be rejected by
App Store Connect is caught before an upload rather than after.

Keywords are limited in UTF-8 BYTES, not characters, which matters the
moment a keyword carries an accent.

Usage: scripts/check-store-metadata.py [files...]   (defaults to all packs)
"""
import glob
import re
import sys
import unicodedata

# Heading forms used across the packs, in any language.
LIMIT_PATTERNS = [
    re.compile(r"\((\d+)\s*chars?\s*max\)", re.I),
    re.compile(r"\(max\.?\s*(\d+)\)", re.I),
    re.compile(r"\(maks\.?\s*(\d+)\)", re.I),
    re.compile(r"\(máx\.?\s*(\d+)\)", re.I),
]
# Fields Apple measures in UTF-8 bytes rather than characters.
BYTE_LIMITED = ("keyword", "parole chiave", "palavras", "palabras",
                "mots-cl", "stichw", "nøkkelord")
# The "(168)" or "(94 bytes)" the author appended to their own block.
TRAILING_COUNT = re.compile(r"\s*\(\d+(?:\s+\w+)?\)\s*$")
# Keyword lines are written as `a,b,c`; measure what is inside the ticks.
BACKTICKED = re.compile(r"`([^`]*)`")


def limit_in(heading):
    for pattern in LIMIT_PATTERNS:
        found = pattern.search(heading)
        if found:
            return int(found.group(1))
    return None


def blocks(path):
    """Yields (heading, limit, text) for every limited section."""
    heading, limit, buffer = None, None, []
    for line in open(path, encoding="utf-8").read().splitlines() + ["## end"]:
        if line.startswith("#"):
            if heading and limit and buffer:
                yield heading, limit, "\n".join(buffer).strip()
            heading, limit, buffer = line, limit_in(line), []
        elif line.startswith(">") and limit:
            buffer.append(line.lstrip("> ").rstrip())
        elif line.startswith("`") and limit:
            found = BACKTICKED.search(line)
            buffer.append(found.group(1) if found else line.strip("`"))


def measure(path):
    problems = []
    for heading, limit, text in blocks(path):
        text = TRAILING_COUNT.sub("", text.replace("\n", " ")).strip()
        # Apple counts a composed character, so normalize before measuring.
        normalized = unicodedata.normalize("NFC", text)
        by_bytes = any(word in heading.lower() for word in BYTE_LIMITED)
        size = len(normalized.encode("utf-8")) if by_bytes else len(normalized)
        unit = "bytes" if by_bytes else "chars"
        if size > limit:
            problems.append(
                f"{path}: {heading.strip('# ')} is {size} {unit}, limit {limit}\n"
                f"    {text[:90]}{'…' if len(text) > 90 else ''}"
            )
    return problems


def main(paths):
    paths = paths or sorted(glob.glob("docs/appstore/metadata*.md"))
    problems = [p for path in paths for p in measure(path)]
    for problem in problems:
        print(problem, file=sys.stderr)
    if problems:
        print(f"\n{len(problems)} field(s) over limit", file=sys.stderr)
        return 1
    print(f"All measured fields fit ({len(paths)} packs).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
