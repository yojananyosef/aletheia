#!/usr/bin/env python3
"""Convierte una Biblia en USFM (eBible.org) al formato de documento del catálogo.

Uso:
    python3 catalog/tools/import_ebible_usfm.py \
        --usfm-dir /tmp/opencode/rv1909/usfm \
        --out-dir  app/assets/catalog/rv1909 \
        --resource-id bible.rv1909 \
        --title "Reina-Valera 1909" \
        --abbrev RV1909 \
        --source-url https://ebible.org/Scriptures/spaRV1909_usfm.zip \
        --license "Dominio público"

Salida:
    <out-dir>/manifest.json          metadatos + índice de libros/capítulos
    <out-dir>/books/<CODE>.json      documento por libro

Formato (contrato 03-contrato-catalogo.md):
    block:  heading | chapterNumber | verseGroup | paragraph | poetry | rule
    inline: text | span(style) | footnote | xref | line

Marcadores USFM soportados: \\id \\h \\toc1 \\toc2 \\mt1 \\c \\p \\m \\q \\li \\s
\\d \\v \\w(...)\\w* \\add(...)\\add* \\f(...)\\f* \\x(...)\\x* y descarta el resto.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# Orden canónico protestante (66 libros).
BOOK_ORDER = [
    "GEN", "EXO", "LEV", "NUM", "DEU", "JOS", "JDG", "RUT", "1SA", "2SA",
    "1KI", "2KI", "1CH", "2CH", "EZR", "NEH", "EST", "JOB", "PSA", "PRO",
    "ECC", "SNG", "ISA", "JER", "LAM", "EZK", "DAN", "HOS", "JOL", "AMO",
    "OBA", "JON", "MIC", "NAM", "HAB", "ZEP", "HAG", "ZEC", "MAL",
    "MAT", "MRK", "LUK", "JHN", "ACT", "ROM", "1CO", "2CO", "GAL", "EPH",
    "PHP", "COL", "1TH", "2TH", "1TI", "2TI", "TIT", "PHM", "HEB", "JAS",
    "1PE", "2PE", "1JN", "2JN", "3JN", "JUD", "REV",
]

# Notas al pie (\f…\f*) y cross-refs (\x…\x*): se descartan por ahora
# (la ingesta completa de notas llegará con el servicio de catálogo en M2).
FN_XREF_RE = re.compile(r"\\[fx]\b.*?\\[fx]\*")
# Un token: \w contenido|attrs\w*  |  \w contenido\w*  |  \add contenido\add*
#          | cualquier otro marcador (se descarta).
TOKEN_RE = re.compile(
    r"\\w\s+(?P<word>[^|\\]*?)\|[^\\]*?\\w\*"
    r"|\\w\s+(?P<word_plain>[^\\]*?)\\w\*"
    r"|\\add\s+(?P<add>[^\\]*?)\\add\*"
    r"|\\[a-z]+[0-9]?\*?"
)
WS_RE = re.compile(r"\s+")
# Espacios sobrantes antes de puntuación (surgen al quitar marcadores).
PUNCT_FIX = [
    (" ,", ","), (" .", "."), (" ;", ";"), (" :", ":"),
    (" !", "!"), (" ?", "?"), (" )", ")"), (" ]", "]"),
    ("( ", "("), ("[ ", "["), ("« ", "«"), (" ¡", "¡"),
]


def clean_runs(runs: list[list]) -> list[list]:
    """Normaliza espacios y fusiona tramos contiguos con el mismo estilo."""
    merged: list[list] = []
    for style, text in runs:
        text = WS_RE.sub(" ", text)
        if not text:
            continue
        if merged and merged[-1][0] == style:
            merged[-1][1] += text
        else:
            merged.append([style, text])
    for pair in merged:
        for find, repl in PUNCT_FIX:
            pair[1] = pair[1].replace(find, repl)
    if merged:
        merged[0][1] = merged[0][1].lstrip()
        merged[-1][1] = merged[-1][1].rstrip()
    return [pair for pair in merged if pair[1] and pair[1] != " "]


def parse_runs(text: str) -> list[list]:
    """Texto USFM → tramos [(style, texto)] donde style ∈ {text, italic}."""
    text = FN_XREF_RE.sub(" ", text)
    runs: list[list] = []
    pos = 0
    for m in TOKEN_RE.finditer(text):
        if m.start() > pos:
            runs.append(["text", text[pos:m.start()]])
        word = m.group("word") or m.group("word_plain") or m.group("add")
        if word is not None:
            runs.append(["italic" if m.group("add") else "text", word])
        pos = m.end()
    if pos < len(text):
        runs.append(["text", text[pos:]])
    return clean_runs(runs)


def runs_to_inlines(runs: list[list]) -> list[dict]:
    out = []
    for style, text in runs:
        if style == "italic":
            out.append({"t": "span", "style": "italic", "v": text})
        else:
            out.append({"t": "text", "v": text})
    return out


def parse_verse_text(text: str) -> list[dict]:
    return runs_to_inlines(parse_runs(text))


def convert_book(path: Path) -> tuple[dict, dict]:
    """Devuelve (libro_json, resumen para el manifest)."""
    lines = path.read_text(encoding="utf-8").splitlines()

    code = None
    name = None
    chapters: list[dict] = []
    blocks: list[dict] = []
    chapter_num = None
    group: dict | None = None  # verseGroup actual
    verse: dict | None = None  # versículo en curso

    def close_group() -> None:
        nonlocal group, verse
        if group is not None and group["verses"]:
            blocks.append(group)
        group = None
        verse = None

    for raw in lines:
        line = raw.rstrip()
        if not line:
            continue

        if line.startswith("\\id "):
            code = line.split()[1].strip()
            continue
        if line.startswith("\\h ") or (line.startswith("\\h") and name is None):
            name = line[2:].strip() or None
            continue
        if line.startswith("\\toc2 ") and name is None:
            name = line[6:].strip() or None
            continue
        if line.startswith("\\mt1 ") or line.startswith("\\toc1 "):
            continue
        if line.startswith("\\c "):
            close_group()
            new_num = int(line.split()[1])
            if chapter_num is not None:
                chapters.append({"n": chapter_num, "blocks": blocks})
                blocks = []
            chapter_num = new_num
            blocks.append({"type": "chapterNumber", "value": new_num})
            continue
        if line.startswith("\\p") or line == "\\m" or line.startswith("\\q") or \
           line.startswith("\\li") or line.startswith("\\s") or line.startswith("\\d"):
            close_group()
            if line.startswith("\\s") or line.startswith("\\d"):
                text = line[line.index(" ") + 1:].strip() if " " in line else ""
                if text:
                    style = "psalmTitle" if line.startswith("\\d") else "section"
                    blocks.append({"type": "heading", "style": style, "text": text})
            elif line.startswith("\\li"):
                group = {"type": "verseGroup", "style": "list", "verses": []}
            elif line.startswith("\\q"):
                level = line[2:].strip()
                indent = int(level) if level.isdigit() else 0
                group = {
                    "type": "verseGroup",
                    "style": "poetry",
                    "indent": max(indent - 1, 0),
                    "verses": [],
                }
            continue
        if line.startswith("\\v "):
            m = re.match(r"\\v\s+(\d+)\s*(.*)$", line)
            if m is None:
                continue
            num = int(m.group(1))
            rest = m.group(2)
            if group is None:
                group = {"type": "verseGroup", "verses": []}
            verse = {"n": num, "inlines": parse_verse_text(rest)}
            group["verses"].append(verse)
            continue

        # Línea de continuación dentro del versículo actual.
        if verse is not None:
            continuation = parse_verse_text(line)
            if continuation:
                verse["inlines"].extend(continuation)

    if chapter_num is not None:
        close_group()
        chapters.append({"n": chapter_num, "blocks": blocks})

    if code is None or name is None:
        raise ValueError(f"No se pudo leer \\id/\\h en {path}")

    summary = {
        "code": code,
        "name": name,
        "chapters": [{"n": ch["n"], "verses": count_verses(ch)} for ch in chapters],
    }
    return {"code": code, "name": name, "chapters": chapters}, summary


def count_verses(chapter: dict) -> int:
    total = 0
    for block in chapter["blocks"]:
        if block["type"] == "verseGroup":
            total += len(block["verses"])
    return total


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--usfm-dir", required=True)
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--resource-id", required=True)
    ap.add_argument("--title", required=True)
    ap.add_argument("--abbrev", required=True)
    ap.add_argument("--language", default="es")
    ap.add_argument("--source-url", required=True)
    ap.add_argument("--license", required=True)
    args = ap.parse_args()

    usfm_dir = Path(args.usfm_dir)
    out_dir = Path(args.out_dir)
    books_dir = out_dir / "books"
    books_dir.mkdir(parents=True, exist_ok=True)

    books: dict[str, dict] = {}
    for path in sorted(usfm_dir.glob("*.usfm")):
        book, summary = convert_book(path)
        books[book["code"]] = {"book": book, "summary": summary}

    missing = [c for c in BOOK_ORDER if c not in books]
    if missing:
        print(f"ERROR: faltan libros: {missing}", file=sys.stderr)
        return 1

    manifest_books = []
    total_chapters = 0
    total_verses = 0
    for code in BOOK_ORDER:
        entry = books[code]
        manifest_books.append(entry["summary"])
        for ch in entry["summary"]["chapters"]:
            total_chapters += 1
            total_verses += ch["verses"]
        payload = json.dumps(entry["book"], ensure_ascii=False, separators=(",", ":"))
        (books_dir / f"{code}.json").write_text(payload, encoding="utf-8")

    manifest = {
        "resourceId": args.resource_id,
        "title": args.title,
        "abbrev": args.abbrev,
        "language": args.language,
        "source": args.source_url,
        "license": args.license,
        "books": manifest_books,
    }
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )

    print(f"OK {args.resource_id}: {len(manifest_books)} libros, "
          f"{total_chapters} capítulos, {total_verses} versículos")
    print(f"Salida: {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
