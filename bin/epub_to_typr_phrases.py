#!/usr/bin/env python3
"""
Turn an EPUB (or an already-pandoc-converted markdown file) into a Lua
`phrases` table for the `typr` Neovim plugin (nvzone/typr), so `:Typr`
practice text is real, readable sentences instead of random words.

Usage:
    bin/epub_to_typr_phrases.py book.epub -o lua/junyi/typr_book.lua \
        --start-heading "The Aims of This Edition" --end-heading "Appendix"

Requires `pandoc` on PATH when given an .epub input.
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path

SKIP_CLASSES = {"list", "references", "figure", "sidebar", "senseline"}
FENCE_RE = re.compile(r"^:{3,}\s*(.*)$")

ABBR = [
    "Mr.", "Mrs.", "Ms.", "Dr.", "Prof.", "Sr.", "Jr.", "St.", "Mt.",
    "vs.", "etc.", "e.g.", "i.e.", "cf.", "pp.", "vol.", "ch.",
    "fig.", "no.", "al.", "Inc.", "Ltd.", "U.S.", "U.K.", "Ph.D.",
    "B.C.", "A.D.", "approx.", "ed.", "eds.", "trans.",
]
PLACEHOLDER = "@@DOT@@"


def epub_to_markdown(epub_path):
    result = subprocess.run(
        ["pandoc", str(epub_path), "-t", "markdown", "--wrap=none"],
        capture_output=True, text=True, check=True,
    )
    return result.stdout.splitlines(keepends=True)


def extract_paragraphs(lines, start_heading, end_heading):
    start_idx = 0
    if start_heading:
        for i, l in enumerate(lines):
            if l.startswith("#") and start_heading in l:
                start_idx = i
                break

    end_idx = len(lines)
    if end_heading:
        for i, l in enumerate(lines):
            if l.startswith("#") and end_heading in l:
                end_idx = i
                break

    body_lines = lines[start_idx:end_idx]

    skip_stack = []

    def cur_skip():
        return any(skip_stack)

    paragraphs = []
    for raw in body_lines:
        line = raw.rstrip("\n")
        stripped = line.strip()
        m = FENCE_RE.match(stripped)
        if m:
            rest = m.group(1).strip()
            if rest == "":
                if skip_stack:
                    skip_stack.pop()
            else:
                if rest.startswith("{"):
                    classes = set(re.findall(r"\.([A-Za-z0-9_-]+)", rest))
                else:
                    classes = {rest.split()[0]}
                skip_stack.append(cur_skip() or bool(classes & SKIP_CLASSES))
            continue
        if cur_skip():
            continue
        if not stripped or stripped.startswith("#"):
            continue
        paragraphs.append(line)

    return paragraphs


def clean_md(s):
    s = re.sub(r"\[\]\{[^}]*\}", "", s)
    s = re.sub(r"\[([^\]]*)\]\([^)]*\)(\{[^}]*\})?", r"\1", s)
    prev = None
    while prev != s:
        prev = s
        s = re.sub(r"\[([^\[\]]*)\]\{[^}]*\}", r"\1", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"\1", s)
    s = re.sub(r"\*([^*]+)\*", r"\1", s)
    s = re.sub(r"(?<!\w)_([^_]+)_(?!\w)", r"\1", s)
    s = s.replace("---", "—").replace("--", "–")
    s = re.sub(r"\s+", " ", s).strip()
    return s


def protect(t):
    for a in ABBR:
        t = re.sub(r"(?<![A-Za-z])" + re.escape(a), a.replace(".", PLACEHOLDER), t)
    # single-letter initials, e.g. "Joseph M. Williams" / "Kate L. Turabian"
    t = re.sub(r"(?<![A-Za-z])([A-Z])\.", r"\1" + PLACEHOLDER, t)
    # decimals like 3.5
    t = re.sub(r"(?<=\d)\.(?=\d)", PLACEHOLDER, t)
    return t


def restore(s):
    return s.replace(PLACEHOLDER, ".")


def split_sentences(paragraph):
    protected = protect(paragraph)
    parts = re.split(r"(?<=[.?!])\s+(?=[“‘'\"]?[A-Z0-9])", protected)
    return [restore(p).strip() for p in parts]


def is_good(s, min_len, max_len):
    if not (min_len <= len(s) <= max_len):
        return False
    if not re.search(r"[a-z]", s):
        return False
    if s[-1] not in ".?!”’\"":
        return False
    if re.search(r"[\[\]{}#|_]", s):
        return False
    if re.search(r"https?://|www\.", s):
        return False
    if re.search(r"\d{4,}", s):
        return False
    if re.search(r"\d+\.\d+\.\d+", s):
        return False
    if len(re.findall(r"\b[A-Z]{2,}\b", s)) > 2:
        return False
    return True


def lua_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input", type=Path, help="EPUB file, or a markdown file already converted by pandoc")
    ap.add_argument("-o", "--output", type=Path, help="output .lua path (default: <input stem>_phrases.lua)")
    ap.add_argument("--start-heading", default=None, help="substring of the first markdown heading to keep from (skips front matter)")
    ap.add_argument("--end-heading", default=None, help="substring of the first markdown heading to cut off at (skips back matter)")
    ap.add_argument("--min-len", type=int, default=40, help="minimum sentence length in characters (default: 40)")
    ap.add_argument("--max-len", type=int, default=220, help="maximum sentence length in characters (default: 220)")
    ap.add_argument("--label", default=None, help="book title/credit for the generated file's header comment")
    args = ap.parse_args()

    if args.input.suffix.lower() == ".epub":
        lines = epub_to_markdown(args.input)
    else:
        lines = args.input.read_text(encoding="utf-8").splitlines(keepends=True)

    paragraphs = extract_paragraphs(lines, args.start_heading, args.end_heading)
    cleaned = [c for c in (clean_md(p) for p in paragraphs) if c]

    sentences = []
    for p in cleaned:
        sentences.extend(split_sentences(p))

    seen = set()
    good = []
    for s in sentences:
        if is_good(s, args.min_len, args.max_len) and s not in seen:
            seen.add(s)
            good.append(s)

    print(f"paragraphs kept: {len(cleaned)}", file=sys.stderr)
    print(f"raw sentences:   {len(sentences)}", file=sys.stderr)
    print(f"good sentences:  {len(good)}", file=sys.stderr)

    output = args.output or args.input.with_name(args.input.stem + "_phrases.lua")
    label = args.label or args.input.stem
    with open(output, "w", encoding="utf-8") as f:
        f.write(f'-- Auto-generated from "{label}" for Typr practice.\n')
        f.write("-- Regenerate with bin/epub_to_typr_phrases.py if needed.\n")
        f.write("return {\n")
        for s in good:
            f.write(f'  "{lua_escape(s)}",\n')
        f.write("}\n")

    print(f"wrote {output}", file=sys.stderr)


if __name__ == "__main__":
    main()
