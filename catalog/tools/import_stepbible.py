#!/usr/bin/env python3
"""Genera los textos originales TAHOT y TAGNT para el catálogo.

Fuente: STEPBible.org / Tyndale House Cambridge, CC BY 4.0.
  https://github.com/STEPBible/STEPBible-Data

- TAHOT: hebreo con vocales, acentos, Strong desambiguado, morfología ETCBC
  y traducción inglesa.
- TAGNT: griego del Nuevo Testamento con Strong desambiguado, morfología y
  traducción inglesa. Se usa la referencia KJV entre corchetes cuando existe,
  porque la app sigue la versificación de la RV1909/KJV.

No se usa la columna «Spanish translation» de TAGNT: procede de OpenGNT y su
licencia (CC BY-SA) es distinta de la CC BY 4.0 del resto de TAGNT. La interfaz
muestra glosas propias en español para las voces más frecuentes y conserva la
glosa inglesa, etiquetada, para el resto.

Uso:
  python3 catalog/tools/import_stepbible.py --kind tahot
  python3 catalog/tools/import_stepbible.py --kind tagnt
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

from stepbible_common import (
    BOOK_MAP,
    BOOK_NAMES_ES,
    SPANISH_GLOSS,
    clean_gloss,
    clean_greek,
    clean_hebrew,
    normalize_strong,
    root_strong,
    STEP_DIR,
    write_morphology_map,
)

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "catalog" / "data"
MORPH_PATH = DATA / "morphology.json"

BOOK_ORDER = [
    "GEN", "EXO", "LEV", "NUM", "DEU", "JOS", "JDG", "RUT", "1SA", "2SA",
    "1KI", "2KI", "1CH", "2CH", "EZR", "NEH", "EST", "JOB", "PSA", "PRO",
    "ECC", "SNG", "ISA", "JER", "LAM", "EZK", "DAN", "HOS", "JOL", "AMO",
    "OBA", "JON", "MIC", "NAM", "HAB", "ZEP", "HAG", "ZEC", "MAL",
    "MAT", "MRK", "LUK", "JHN", "ACT", "ROM", "1CO", "2CO", "GAL", "EPH",
    "PHP", "COL", "1TH", "2TH", "1TI", "2TI", "TIT", "PHM", "HEB", "JAS",
    "1PE", "2PE", "1JN", "2JN", "3JN", "JUD", "REV",
]

REF_RE = re.compile(
    r"^([1-3]?[A-Z][a-z]{1,2})\.(\d+)\.(\d+)"
    r"((?:\([^)]*\)|\[[^\]]*\])*)#(\d+)(?:=([^\t]*))?"
)
ALT_KJV_RE = re.compile(r"\[(\d+)\.(\d+)\]")
PAREN_ALT_RE = re.compile(r"\((\d+)\.(\d+)\)")

# Los libros poéticos se muestran un versículo por línea; los narrativos
# fluyen como párrafos.
POETRY = {"JOB", "PSA", "PRO", "ECC", "SNG", "LAM"}


def parse_reference(line: str, kind: str):
    """Devuelve (canonical_ref, base_ref, word_num, source_type) o None."""
    m = REF_RE.match(line)
    if not m:
        return None
    book = BOOK_MAP.get(m.group(1))
    if book is None:
        return None
    chapter = int(m.group(2))
    verse = int(m.group(3))
    extra = m.group(4) or ""
    word_num = int(m.group(5))
    source_type = (m.group(6) or "").strip()

    canonical = (book, chapter, verse)
    if kind == "tagnt":
        # En TAGNT el corchete es la versificación KJV. Si existe, esa fila
        # pertenece a la referencia KJV; sin corchete se usa la NRSV base.
        alt = ALT_KJV_RE.search(extra)
        if alt:
            canonical = (book, int(alt.group(1)), int(alt.group(2)))
    return canonical, (book, chapter, verse), word_num, source_type


def parse_tahot_row(line: str):
    cols = line.split("\t")
    if len(cols) < 6:
        return None
    parsed = parse_reference(line, "tahot")
    if parsed is None:
        return None
    canonical, base, word_num, source_type = parsed
    if word_num >= 500 or source_type.upper().startswith("X"):
        # 0501... son añadidos de la LXX; no forman parte del canon hebreo
        # protestante que usa la app. X son conjeturas basadas en la LXX.
        return None
    hebrew = clean_hebrew(cols[1])
    if not hebrew:
        return None
    strong, strong_full = root_strong(cols[4])
    gloss = clean_gloss(cols[3])
    word = {
        "text": hebrew,
        "strong": strong,
        "strongFull": strong_full,
        "morph": cols[5].strip() or None,
        "translit": cols[2].strip() or None,
        "gloss": gloss or None,
        "glossEs": SPANISH_GLOSS.get(strong) if strong else None,
        "code": source_type,
    }
    return canonical, base, word_num, word


def parse_tagnt_row(line: str):
    cols = line.split("\t")
    if len(cols) < 6:
        return None
    parsed = parse_reference(line, "tagnt")
    if parsed is None:
        return None
    canonical, base, word_num, source_type = parsed
    greek, translit = clean_greek(cols[1])
    if not greek:
        return None
    dstrong = cols[3].split("=", 1)[0]
    grammar = cols[3].split("=", 1)[1] if "=" in cols[3] else ""
    strong, strong_full = root_strong(dstrong)
    dictionary = cols[4]
    lemma = dictionary.split("=", 1)[0].strip() if "=" in dictionary else None
    gloss = dictionary.split("=", 1)[1].strip() if "=" in dictionary else ""
    if not gloss:
        gloss = clean_gloss(cols[2])
    word = {
        "text": greek,
        "strong": strong,
        "strongFull": strong_full,
        "morph": grammar.strip() or None,
        "lemma": lemma or None,
        "translit": translit,
        "gloss": clean_gloss(gloss) or None,
        "glossEs": SPANISH_GLOSS.get(strong) if strong else None,
        "code": source_type,
    }
    return canonical, base, word_num, word


def source_priority(word: dict, kind: str) -> tuple:
    """Prioridad para elegir una fila cuando hay variantes de la misma palabra."""
    code = (word.get("code") or "").upper()
    if kind == "tahot":
        # Los traductores siguen la Qere cuando hay elección Q/K; L es la
        # forma de Leningrado y R el texto restaurado.
        if code.startswith("Q"):
            group = 0
        elif code.startswith("L"):
            group = 1
        elif code.startswith("R"):
            group = 2
        elif code.startswith("K"):
            group = 3
        else:
            group = 4
        return (group, len(code), code)
    # TAGNT: preferir la lectura antigua (N), luego la tradicional (K), luego
    # las demás ediciones. Las filas con NKO exacta son la lectura principal.
    has_n = 0 if "N" in code else 1
    exact = 0 if code.startswith("NKO") or code.startswith("NK(O)") else 1
    return (has_n, exact, len(code), code)


def choose_rows(rows: list[tuple], kind: str):
    """Agrupa candidatos por (referencia de origen, número de palabra)."""
    grouped: dict[tuple, list[tuple]] = defaultdict(list)
    base_has_n: dict[tuple, bool] = defaultdict(bool)
    for sequence, canonical, base, word_num, word in rows:
        # La clave es la referencia de origen, no la canónica: al fusionar
        # Rev.12.18[13.1] con Rev.13.1 los números de palabra se reinician.
        grouped[(base, word_num)].append((sequence, canonical, word))
        if "N" in (word.get("code") or "").upper():
            base_has_n[base] = True
    chosen = []
    for (base, word_num), candidates in grouped.items():
        has_n = any(
            "N" in (c[2].get("code") or "").upper() for c in candidates
        )
        # En una referencia con texto NA, no añadir palabras que solo existen
        # en el Textus Receptus (p. ej. la suscripción de 2Co 13).
        if kind == "tagnt" and base_has_n[base] and not has_n:
            continue
        best = min(candidates, key=lambda c: (source_priority(c[2], kind), c[0]))
        chosen.append((best[0], best[1], word_num, best[2]))
    chosen.sort(key=lambda item: (item[0], item[2]))
    return chosen


def build(kind: str, out_dir: Path, resource_id: str, title: str,
          abbrev: str, source_url: str, license_text: str) -> None:
    pattern = "TAHOT*.txt" if kind == "tahot" else "TAGNT*.txt"
    files = sorted(STEP_DIR.glob(pattern))
    if not files:
        raise SystemExit(f"ERROR: no hay archivos {pattern} en {STEP_DIR}")

    rows = []
    morph_codes: set[str] = set()
    line_sequence = 0
    for path in files:
        for line in path.read_text(encoding="utf-8-sig").splitlines():
            if not line or line.startswith("#"):
                continue
            parsed = parse_tahot_row(line) if kind == "tahot" else parse_tagnt_row(line)
            if parsed is None:
                continue
            canonical, base, word_num, word = parsed
            morph = word.get("morph")
            if morph:
                morph_codes.add(morph)
            # El orden de lectura dentro de una referencia fusionada (por
            # ejemplo Rev.12.18[13.1] + Rev.13.1) sigue el orden del archivo.
            rows.append((line_sequence, canonical, base, word_num, word))
            line_sequence += 1

    chosen = choose_rows(rows, kind)

    books: dict[str, dict[int, dict[int, list[dict]]]] = defaultdict(
        lambda: defaultdict(lambda: defaultdict(list))
    )
    for _, (book, chapter, verse), _, word in chosen:
        books[book][chapter][verse].append(word)

    manifest_books = []
    total_chapters = 0
    total_verses = 0
    book_dir = out_dir / "books"
    book_dir.mkdir(parents=True, exist_ok=True)

    for code in BOOK_ORDER:
        if code not in books:
            continue
        chapters = books[code]
        max_chapter = max(chapters)
        chapter_docs = []
        chapter_summaries = []
        for chapter_num in range(1, max_chapter + 1):
            verses = chapters.get(chapter_num, {})
            blocks = [{"type": "chapterNumber", "value": chapter_num}]
            verse_docs = []
            for verse_num in sorted(verses):
                words = verses[verse_num]
                inlines = []
                for index, word in enumerate(words):
                    suffix = " " if index + 1 < len(words) else ""
                    inline = {"t": "text", "v": word["text"] + suffix}
                    for key in (
                        "strong", "strongFull", "morph", "lemma", "translit",
                        "gloss", "glossEs",
                    ):
                        if word.get(key):
                            inline[key] = word[key]
                    inlines.append(inline)
                if inlines:
                    verse_docs.append({"n": verse_num, "inlines": inlines})
            if verse_docs:
                blocks.append(
                    {
                        "type": "verseGroup",
                        "style": "poetry" if code in POETRY else "paragraph",
                        "verses": verse_docs,
                    }
                )
            chapter_docs.append({"n": chapter_num, "blocks": blocks})
            numbered = sum(1 for v in verses if v > 0)
            chapter_summaries.append({"n": chapter_num, "verses": numbered})
            total_chapters += 1
            total_verses += numbered

        doc = {
            "code": code,
            "name": BOOK_NAMES_ES[code],
            "chapters": chapter_docs,
        }
        (book_dir / f"{code}.json").write_text(
            json.dumps(doc, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8",
        )
        manifest_books.append(
            {
                "code": code,
                "name": BOOK_NAMES_ES[code],
                "chapters": chapter_summaries,
            }
        )

    manifest = {
        "resourceId": resource_id,
        "title": title,
        "abbrev": abbrev,
        "language": "he" if kind == "tahot" else "grc",
        "source": source_url,
        "license": license_text,
        "attributes": {
            "original": True,
            "strongs": True,
            "morphology": "ETCBC/Tyndale House" if kind == "tahot" else "TAGNT",
            "rtl": kind == "tahot",
            "versification": "KJV/RV1909",
        },
        "books": manifest_books,
    }
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    write_morphology_map(morph_codes, greek=(kind == "tagnt"), path=MORPH_PATH)
    print(
        f"OK {resource_id}: {len(manifest_books)} libros, {total_chapters} "
        f"capítulos, {total_verses} versículos, {len(chosen)} palabras"
    )
    print(f"Salida: {out_dir}")
    print(f"Morfología: {MORPH_PATH} ({len(morph_codes)} códigos)")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--kind", choices=("tahot", "tagnt"), required=True)
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--resource-id")
    ap.add_argument("--title")
    ap.add_argument("--abbrev")
    ap.add_argument("--source-url", default="https://github.com/STEPBible/STEPBible-Data")
    ap.add_argument(
        "--license",
        default="CC BY 4.0 — STEPBible.org / Tyndale House Cambridge",
    )
    args = ap.parse_args()
    out_dir = Path(args.out_dir)
    if not out_dir.is_absolute():
        out_dir = ROOT / out_dir
    if args.kind == "tahot":
        resource_id = args.resource_id or "bible.tahot"
        title = args.title or "Texto hebreo (TAHOT)"
        abbrev = args.abbrev or "TAHOT"
    else:
        resource_id = args.resource_id or "bible.tagnt"
        title = args.title or "Texto griego (TAGNT)"
        abbrev = args.abbrev or "TAGNT"
    build(
        args.kind, out_dir, resource_id, title, abbrev,
        args.source_url, args.license,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
